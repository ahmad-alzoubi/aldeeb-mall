class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role; // 'customer', 'admin', 'cashier', 'driver'
  final int loyaltyPoints;
  final String tier; // 'Silver', 'Gold', 'Platinum'

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.role = 'customer',
    this.loyaltyPoints = 50,
    this.tier = 'Silver',
  });

  bool get isAdmin => role == 'admin';

  double get pointsCashValue => loyaltyPoints * 0.01; // 100 points = 1.00 AED/currency

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'عميل الديب مول',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String? ?? 'Silver',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'loyalty_points': loyaltyPoints,
      'tier': tier,
    };
  }
}
