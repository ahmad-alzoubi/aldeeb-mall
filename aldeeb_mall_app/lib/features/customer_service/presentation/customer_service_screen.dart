import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/store_settings_provider.dart';
import '../models/support_ticket_model.dart';
import '../services/customer_service_service.dart';

class CustomerServiceScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialOrderNumber;
  final String? initialSubject;

  const CustomerServiceScreen({
    super.key,
    this.initialCategory,
    this.initialOrderNumber,
    this.initialSubject,
  });

  static void show(
    BuildContext context, {
    String? initialCategory,
    String? initialOrderNumber,
    String? initialSubject,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerServiceScreen(
          initialCategory: initialCategory,
          initialOrderNumber: initialOrderNumber,
          initialSubject: initialSubject,
        ),
      ),
    );
  }

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen>
    with SingleTickerProviderStateMixin {
  final CustomerServiceService _service = CustomerServiceService();
  late TabController _tabController;

  // Live Chat State
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<TicketMessage> _liveChatMessages = [];
  bool _isTyping = false;
  Timer? _pollTimer;

  // Tickets State
  List<SupportTicket> _tickets = [];
  bool _isLoadingTickets = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _initLiveChat();
    _loadTickets();

    // Periodic Realtime Background Sync (Free & Instant across tabs and devices)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _syncIncomingMessages();
      }
    });

    if (widget.initialOrderNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleOrderQuickStart(widget.initialOrderNumber!);
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _initLiveChat() async {
    final liveTicket = await _service.getOrCreateLiveChatTicket(
      orderNumber: widget.initialOrderNumber,
    );
    if (!mounted) return;
    setState(() {
      _liveChatMessages.clear();
      if (liveTicket.messages.isNotEmpty) {
        _liveChatMessages.addAll(liveTicket.messages);
      } else {
        _liveChatMessages.add(
          TicketMessage(
            id: 'welcome-1',
            sender: 'bot',
            senderName: 'مساعد الديب الذكي',
            text:
                'مرحباً بك في مركز خدمة عملاء الديب مول 🛒✨\nنحن هنا لخدمتك 24/7. يمكنك الاستفسار عن طلباتك، سياسة الضمان والاسترجاع، ومتابعة شحناتك.',
            timestamp: 'الآن',
          ),
        );
      }
    });
    _scrollToBottom();
  }

  Future<void> _syncIncomingMessages() async {
    try {
      final data = await _service.getTickets();
      if (!mounted) return;

      final liveTkt = data.firstWhere(
        (t) => t.id == 'tkt-live-chat' || t.category == 'live_chat',
        orElse: () => data.isNotEmpty ? data.first : SupportTicket(
          id: 'dummy',
          ticketNumber: '0',
          customerName: '',
          subject: '',
          status: 'open',
          priority: 'low',
          createdAt: '',
          lastMessage: '',
        ),
      );

      bool hasNew = false;
      if (liveTkt.id == 'tkt-live-chat' && liveTkt.messages.isNotEmpty) {
        final existingIds = _liveChatMessages.map((m) => m.id).toSet();
        for (final m in liveTkt.messages) {
          if (!existingIds.contains(m.id)) {
            _liveChatMessages.add(m);
            hasNew = true;
          }
        }
      }

      setState(() {
        _tickets = data;
        _isLoadingTickets = false;
      });

      if (hasNew) {
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _handleOrderQuickStart(String orderNum) {
    setState(() {
      _liveChatMessages.add(
        TicketMessage(
          id: 'order-req',
          sender: 'customer',
          senderName: 'أنا',
          text: 'استفسار بخصوص طلبي رقم #$orderNum',
          timestamp: 'الآن',
        ),
      );
      _liveChatMessages.add(
        TicketMessage(
          id: 'order-rep',
          sender: 'bot',
          senderName: 'مساعد الديب الذكي',
          text:
              'تم ربط طلبك رقم #$orderNum بنجاح. المندوب في طريقه إليك بدرجة تبريد آمنة، ويمكنك مراقبة موقعه أو الاتصال به مباشرة.',
          timestamp: 'الآن',
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoadingTickets = true);
    final data = await _service.getTickets();
    if (mounted) {
      setState(() {
        _tickets = data;
        _isLoadingTickets = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendLiveChatMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final userMsg = TicketMessage(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      sender: 'customer',
      senderName: 'أنا',
      text: clean,
      timestamp: 'الآن',
    );

    setState(() {
      _liveChatMessages.add(userMsg);
      _isTyping = true;
    });
    _chatController.clear();
    _scrollToBottom();

    // 1. Sync user message to local cache and Supabase backend immediately
    _service.addMessageToTicket(
      'tkt-live-chat',
      clean,
      sender: 'customer',
      senderName: 'العميل',
    );

    // 2. Generate smart instant AI assistant response if within 700ms
    Future.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final replyText = _service.getSmartAiResponse(clean, orderNumber: widget.initialOrderNumber);
      final botMsg = TicketMessage(
        id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
        sender: 'agent',
        senderName: 'فريق خدمة العملاء',
        text: replyText,
        timestamp: 'الآن',
      );

      setState(() {
        _isTyping = false;
        _liveChatMessages.add(botMsg);
      });
      _scrollToBottom();

      // Persist agent response to ticket
      await _service.addMessageToTicket(
        'tkt-live-chat',
        replyText,
        sender: 'agent',
        senderName: 'فريق خدمة العملاء',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<StoreSettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: settings.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'خدمة عملاء ${settings.storeNameAr}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'متصلون الآن • دعم فوري 24/7',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'محادثة واتساب سريعة',
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            onPressed: () => _service.launchWhatsApp(
              settings.whatsapp,
              message: 'مرحباً خدمة عملاء ${settings.storeNameAr}، أود الاستفسار والمساعدة.',
            ),
          ),
          IconButton(
            tooltip: 'اتصال هاتفي بالخط الساخن',
            icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
            onPressed: () => _service.callPhone(settings.phone),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: settings.primaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: settings.primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_unread_chat_alt_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('المحادثة الحية'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('تذاكري والشكاوى'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help_outline_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('الأسئلة والضمان'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Quick Hotline Launch Bar
          _buildQuickActionCards(settings),

          // Main Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveChatTab(settings),
                _buildTicketsTab(settings),
                _buildFaqTab(settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Contact Cards Header
  Widget _buildQuickActionCards(StoreSettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // WhatsApp Button
          Expanded(
            child: InkWell(
              onTap: () => _service.launchWhatsApp(
                settings.whatsapp,
                message: 'مرحباً خدمة عملاء ${settings.storeNameAr}، أود الاستفسار.',
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble, color: Color(0xFF1EBE5D), size: 18),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'واتساب فوري',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF128C7E),
                          ),
                        ),
                        Text('رد خلال دقيقة', style: TextStyle(fontSize: 9, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Hotline Call
          Expanded(
            child: InkWell(
              onTap: () => _service.callPhone(settings.phone),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: settings.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: settings.primaryColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_in_talk, color: settings.primaryColor, size: 18),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'الخط الساخن',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: settings.primaryColor,
                          ),
                        ),
                        const Text('مكالمة هاتفية', style: TextStyle(fontSize: 9, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // New Ticket Quick Trigger
          Expanded(
            child: InkWell(
              onTap: () => _showCreateTicketSheet(settings),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_task_rounded, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'فتح تذكرة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        Text('شكوى أو طلب', style: TextStyle(fontSize: 9, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Live Chat Tab
  Widget _buildLiveChatTab(StoreSettingsProvider settings) {
    return Column(
      children: [
        // Quick Question Chips
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildSuggestionChip('🚚 أين وصل طلبي الآن؟'),
              _buildSuggestionChip('🛡️ ما هي سياسة الاسترجاع والضمان؟'),
              _buildSuggestionChip('❄️ كيف تضمنون السلسلة الباردة؟'),
              _buildSuggestionChip('⭐ كيف أحول نقاط المكافآت؟'),
              _buildSuggestionChip('🕒 ما هي مواعيد العمل والتوصيل؟'),
            ],
          ),
        ),

        // Chat Message Stream
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(14),
            itemCount: _liveChatMessages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _liveChatMessages.length && _isTyping) {
                return _buildTypingIndicator(settings);
              }
              final msg = _liveChatMessages[index];
              final isUser = msg.sender == 'customer';
              return _buildChatBubble(msg, isUser, settings);
            },
          ),
        ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'اكتب استفسارك أو مشكلتك هنا...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendLiveChatMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: settings.primaryColor,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendLiveChatMessage(_chatController.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _sendLiveChatMessage(text),
      ),
    );
  }

  Widget _buildChatBubble(TicketMessage msg, bool isUser, StoreSettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: settings.primaryColor.withValues(alpha: 0.12),
              radius: 16,
              child: Icon(Icons.support_agent_rounded, size: 18, color: settings.primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, right: 4),
                    child: Text(
                      msg.senderName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? settings.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                  child: Text(
                    msg.timestamp,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: settings.primaryColor,
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(StoreSettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: settings.primaryColor.withValues(alpha: 0.12),
            radius: 16,
            child: Icon(Icons.support_agent_rounded, size: 18, color: settings.primaryColor),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('فريق الخدمة يكتب الآن', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: settings.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Tickets Tab
  Widget _buildTicketsTab(StoreSettingsProvider settings) {
    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متابعة التذاكر الرسمية والشكاوى',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'جميع التذاكر تخضع للرقابة المباشرة من إدارة الديب مول وتُحل خلال وقت قياسي.',
                        style: TextStyle(color: Colors.black87, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateTicketSheet(settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('تذكرة جديدة'),
                ),
              ],
            ),
          ),

          // Tickets List
          Expanded(
            child: _tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد تذاكر دعم مسجلة حالياً',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'إذا واجهت أي استفسار أو مشكلة في التوصيل أو جودة المنتجات، افتح تذكرة فوراً.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showCreateTicketSheet(settings),
                          style: ElevatedButton.styleFrom(backgroundColor: settings.primaryColor),
                          child: const Text('فتح أول تذكرة دعم', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final t = _tickets[index];
                      return _buildTicketCard(t, settings);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, StoreSettingsProvider settings) {
    Color statusBg;
    Color statusColor;
    String statusLabel;

    if (ticket.status == 'resolved') {
      statusBg = const Color(0xFFD1FAE5);
      statusColor = const Color(0xFF065F46);
      statusLabel = 'تم الحل بنجاح';
    } else if (ticket.status == 'in_progress') {
      statusBg = const Color(0xFFDBEAFE);
      statusColor = const Color(0xFF1E40AF);
      statusLabel = 'قيد المتابعة من المشرف';
    } else {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFF991B1B);
      statusLabel = 'جديدة وبانتظار الرد';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showTicketDetailModal(ticket, settings),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.ticketNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (ticket.orderNumber != null && ticket.orderNumber!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'طلب: ${ticket.orderNumber}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.lastMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تاريخ الإنشاء: ${ticket.createdAt}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  Row(
                    children: [
                      Text(
                        '${ticket.messages.length} رسائل',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: settings.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: settings.primaryColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. FAQ & Guarantee Tab
  Widget _buildFaqTab(StoreSettingsProvider settings) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Freshness Guarantee Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF065F46), const Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF065F46).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'ميثاق الجودة والطزاجة 100% من الديب مول',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'نلتزم بأعلى معايير فحص الخضار، الفواكه، المخبوزات واللحوم الطازجة يومياً. جميع الطلبات تُنقل بسيارات مبردة تدعم السلسلة الباردة المعتمدة. في حال عدم رضاك عن أي صنف، يُعاد المبلغ فوراً دون أي نقاش.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'الأسئلة الشائعة والأجوبة الفورية',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),

        _buildFaqAccordion(
          title: 'ما هي سرعة التوصيل الإكسبريس وكيف يعمل؟',
          body:
              'التوصيل الإكسبريس في الديب مول يستغرق بين 15 إلى 30 دقيقة داخل النطاق المغطى بفضل شبكة مستودعاتنا المظلمة (Dark Stores) الموزعة جغرافياً.',
        ),
        _buildFaqAccordion(
          title: 'ماذا أفعل في حال وصول منتج تالف أو صنف ناقص؟',
          body:
              'يمكنك فوراً فتح تذكرة دعم مع تحديد رقم الطلب أو التحدث عبر الواتساب المباشر، وسيتم تعويضك إما بمنتج بديل فوري مع كابتن إكسبريس أو استرجاع القيمة لمحفظتك.',
        ),
        _buildFaqAccordion(
          title: 'كيف تضمنون جودة الخضار والفواكه واللحوم؟',
          body:
              'تخضع منتجاتنا لفحص دقيق ومستمر عند الاستلام من المزارع المحلية، وتُحفظ في غرف تبريد تخضع لرقابة حرارية دقيقة حتى تسليمها لك.',
        ),
        _buildFaqAccordion(
          title: 'كيف أحصل على التوصيل المجاني؟',
          body:
              'تحصل على توصيل مجاني تلقائياً عند تجاوز سلة مشترياتك الحد الأدنى المحدد في المتجر (100 ل.س أو حسب العروض اليومية النشطة).',
        ),
        _buildFaqAccordion(
          title: 'كيف يتم حساب نقاط الولاء واستبدالها؟',
          body:
              'تكسب نقاط ولاء على كل عملية شراء ناجحة. النقاط يمكن تحويلها بنقرة واحدة من صفحة "برنامج الولاء" إلى كوبونات تخفيض مباشرة أو منتجات مجانية.',
        ),
      ],
    );
  }

  Widget _buildFaqAccordion({required String title, required String body}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        children: [
          Text(body, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
        ],
      ),
    );
  }

  // Modal Sheet: Create New Ticket
  void _showCreateTicketSheet(StoreSettingsProvider settings) {
    final titleCtrl = TextEditingController(text: widget.initialSubject ?? '');
    final msgCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: widget.initialOrderNumber ?? '');
    String selectedCategory = widget.initialCategory ?? 'order_issue';
    String selectedPriority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'فتح تذكرة دعم / شكوى جديدة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Category Selector
                    const Text('تصنيف المشكلة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCatChoice('order_issue', 'مشكلة بالطلب', selectedCategory, (v) {
                          setSheetState(() => selectedCategory = v);
                        }),
                        _buildCatChoice('delivery', 'تأخر التوصيل', selectedCategory, (v) {
                          setSheetState(() => selectedCategory = v);
                        }),
                        _buildCatChoice('quality', 'جودة المنتجات', selectedCategory, (v) {
                          setSheetState(() => selectedCategory = v);
                        }),
                        _buildCatChoice('freshness', 'طزاجة وتبريد', selectedCategory, (v) {
                          setSheetState(() => selectedCategory = v);
                        }),
                        _buildCatChoice('general', 'استفسار عام', selectedCategory, (v) {
                          setSheetState(() => selectedCategory = v);
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Order Number (optional)
                    TextField(
                      controller: orderCtrl,
                      decoration: InputDecoration(
                        labelText: 'رقم الطلب المرتبط (اختياري)',
                        hintText: 'مثال: DEEB-8843',
                        prefixIcon: const Icon(Icons.receipt_long_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subject
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'عنوان التذكرة أو ملخص المشكلة',
                        hintText: 'مثال: نقص في أصناف السلة أو تأخر الكابتن',
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message Details
                    TextField(
                      controller: msgCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'تفاصيل الاستفسار أو الشكوى بالتفصيل',
                        hintText: 'يرجى كتابة التفاصيل لنتمكن من معالجة طلبك بأسرع وقت...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يرجى كتابة عنوان المشكلة وتفاصيلها.')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final newT = await _service.createTicket(
                            subject: titleCtrl.text.trim(),
                            category: selectedCategory,
                            message: msgCtrl.text.trim(),
                            orderNumber: orderCtrl.text.trim().isNotEmpty ? orderCtrl.text.trim() : null,
                            priority: selectedPriority,
                          );

                          await _loadTickets();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('تم إنشاء التذكرة بنجاح برقم ${newT.ticketNumber}'),
                              backgroundColor: const Color(0xFF059669),
                            ),
                          );
                          _tabController.animateTo(1);
                        },
                        child: const Text(
                          'إرسال التذكرة لفريق خدمة العملاء',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCatChoice(String val, String label, String current, Function(String) onSelect) {
    final isSelected = val == current;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => onSelect(val),
    );
  }

  // Modal Sheet: View Ticket Details & Reply
  void _showTicketDetailModal(SupportTicket ticket, StoreSettingsProvider settings) {
    final replyCtrl = TextEditingController();
    SupportTicket currentTicket = ticket;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  currentTicket.ticketNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (currentTicket.orderNumber != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• طلب #${currentTicket.orderNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: settings.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTicket.subject,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: currentTicket.messages.length,
                      itemBuilder: (context, index) {
                        final m = currentTicket.messages[index];
                        final isMe = m.sender == 'customer';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? settings.primaryColor : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.senderName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isMe ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isMe ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m.timestamp,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isMe ? Colors.white60 : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Reply input
                  Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                      top: 10,
                      left: 14,
                      right: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyCtrl,
                            decoration: const InputDecoration(
                              hintText: 'اكتب رداً على التذكرة...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send_rounded, color: settings.primaryColor),
                          onPressed: () async {
                            final text = replyCtrl.text.trim();
                            if (text.isEmpty) return;
                            replyCtrl.clear();

                            final updated = await _service.addMessageToTicket(
                              currentTicket.id,
                              text,
                              sender: 'customer',
                              senderName: 'العميل',
                            );
                            setModalState(() {
                              currentTicket = updated;
                            });
                            _loadTickets();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
