class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.category = 'گشتی', // General
    this.note = '',
  });

  final String id;
  final String title;
  final double amount;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final String category;
  final String note;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      createdByName: json['createdByName'] as String? ?? '',
      category: json['category'] as String? ?? 'گشتی',
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'category': category,
      'note': note,
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    String? category,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }
}
