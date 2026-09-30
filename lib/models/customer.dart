/// مۆدێلی کڕیار و سیستەمی پۆینتی وەفاداری (Loyalty Points System).
class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.points = 0,
    this.totalSpent = 0,
    this.totalPointsEarned = 0,
    this.totalPointsUsed = 0,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;

  /// بڕی پۆینتی ئێستای بەردەست بۆ بەکارهێنان
  final int points;

  /// کۆی بڕی ئەو پارەیەی کڕیار لە سەرەتاوە کڕینی پێکردووە
  final double totalSpent;

  /// کۆی ئەو پۆینتانەی لە هەموو کڕینەکانییەوە کۆی کردووەتەوە
  final int totalPointsEarned;

  /// کۆی ئەو پۆینتانەی لە کڕینەکاندا بەکاریهێناوە بۆ داشکاندن
  final int totalPointsUsed;

  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    int? points,
    double? totalSpent,
    int? totalPointsEarned,
    int? totalPointsUsed,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      points: points ?? this.points,
      totalSpent: totalSpent ?? this.totalSpent,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      totalPointsUsed: totalPointsUsed ?? this.totalPointsUsed,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'phone': phone,
    'points': points,
    'totalSpent': totalSpent,
    'totalPointsEarned': totalPointsEarned,
    'totalPointsUsed': totalPointsUsed,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    points: (json['points'] as num?)?.toInt() ?? 0,
    totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
    totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
    totalPointsUsed: (json['totalPointsUsed'] as num?)?.toInt() ?? 0,
    note: json['note'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
