class TicketMessage {
  final String id;
  final String sender; // 'customer' | 'agent' | 'bot' | 'system'
  final String senderName;
  final String text;
  final String timestamp;

  const TicketMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'customer',
      senderName: json['sender_name']?.toString() ?? (json['sender'] == 'agent' ? 'خدمة العملاء' : 'العميل'),
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? json['time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'sender_name': senderName,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class SupportTicket {
  final String id;
  final String ticketNumber;
  final String customerName;
  final String customerPhone;
  final String? orderNumber;
  final String subject;
  final String category; // 'order_issue', 'delivery', 'pharmacy', 'quality', 'general', 'suggestion'
  final String status; // 'open', 'in_progress', 'resolved'
  final String priority; // 'low', 'medium', 'high'
  final String createdAt;
  final String lastMessage;
  final List<TicketMessage> messages;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.customerName,
    this.customerPhone = '',
    this.orderNumber,
    required this.subject,
    this.category = 'general',
    this.status = 'open',
    this.priority = 'medium',
    required this.createdAt,
    required this.lastMessage,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    List<TicketMessage> msgList = [];
    if (json['messages'] is List) {
      msgList = (json['messages'] as List)
          .map((m) => TicketMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return SupportTicket(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? json['ticketNumber']?.toString() ?? 'TKT-0000',
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString() ?? 'عميل الديب مول',
      customerPhone: json['customer_phone']?.toString() ?? json['customerPhone']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['orderNumber']?.toString(),
      subject: json['subject']?.toString() ?? 'طلب مساعدة',
      category: json['category']?.toString() ?? 'general',
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'medium',
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? 'الآن',
      lastMessage: json['last_message']?.toString() ?? json['lastMessage']?.toString() ?? '',
      messages: msgList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'order_number': orderNumber,
      'subject': subject,
      'category': category,
      'status': status,
      'priority': priority,
      'created_at': createdAt,
      'last_message': lastMessage,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? ticketNumber,
    String? customerName,
    String? customerPhone,
    String? orderNumber,
    String? subject,
    String? category,
    String? status,
    String? priority,
    String? createdAt,
    String? lastMessage,
    List<TicketMessage>? messages,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderNumber: orderNumber ?? this.orderNumber,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
    );
  }
}
