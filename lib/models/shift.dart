class Shift {
  const Shift({
    required this.id,
    required this.openedAt,
    required this.openedBy,
    this.startingCash = 0,
    this.closedAt,
    this.actualCash,
    this.expectedCash,
    this.note,
  });

  final String id;
  final DateTime openedAt;
  final String openedBy;
  final double startingCash;
  final DateTime? closedAt;
  final double? actualCash;
  final double? expectedCash;
  final String? note;

  bool get isOpen => closedAt == null;

  Shift copyWith({
    String? id,
    DateTime? openedAt,
    String? openedBy,
    double? startingCash,
    DateTime? closedAt,
    double? actualCash,
    double? expectedCash,
    String? note,
  }) {
    return Shift(
      id: id ?? this.id,
      openedAt: openedAt ?? this.openedAt,
      openedBy: openedBy ?? this.openedBy,
      startingCash: startingCash ?? this.startingCash,
      closedAt: closedAt ?? this.closedAt,
      actualCash: actualCash ?? this.actualCash,
      expectedCash: expectedCash ?? this.expectedCash,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'openedAt': openedAt.toIso8601String(),
        'openedBy': openedBy,
        'startingCash': startingCash,
        'closedAt': closedAt?.toIso8601String(),
        'actualCash': actualCash,
        'expectedCash': expectedCash,
        'note': note,
      };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String,
        openedAt: DateTime.parse(json['openedAt'] as String),
        openedBy: json['openedBy'] as String? ?? '',
        startingCash: (json['startingCash'] as num?)?.toDouble() ?? 0,
        closedAt: json['closedAt'] == null
            ? null
            : DateTime.tryParse(json['closedAt'] as String),
        actualCash: (json['actualCash'] as num?)?.toDouble(),
        expectedCash: (json['expectedCash'] as num?)?.toDouble(),
        note: json['note'] as String?,
      );
}