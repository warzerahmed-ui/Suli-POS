import 'cart_item.dart';
import 'product_unit.dart';

/// شێوازی پارەدان.
/// English: how the customer paid.
enum PaymentMethod {
  cash('نەقد'),
  card('کارت'),
  credit('قەرز');

  const PaymentMethod(this.label);

  final String label;

  static PaymentMethod fromName(String? name) => PaymentMethod.values.firstWhere(
        (PaymentMethod method) => method.name == name,
        orElse: () => PaymentMethod.cash,
      );
}

/// یەک دێری کاڵا لە ناو پسووڵە.
class SaleItem {
  const SaleItem({
    required this.productId,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.unitCost,
    required this.quantity,
  });

  factory SaleItem.fromCartItem(CartItem item) => SaleItem(
        productId: item.productId,
        name: item.name,
        unit: item.unit,
        unitPrice: item.unitPrice,
        unitCost: item.unitCost,
        quantity: item.quantity,
      );

  final String productId;
  final String name;
  final ProductUnit unit;
  final double unitPrice;
  final double unitCost;
  final double quantity;

  double get total => unitPrice * quantity;

  double get totalCost => unitCost * quantity;

  double get profit => total - totalCost;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'productId': productId,
        'name': name,
        'unit': unit.name,
        'unitPrice': unitPrice,
        'unitCost': unitCost,
        'quantity': quantity,
      };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        unit: ProductUnit.fromName(json['unit'] as String?),
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      );
}

/// پسووڵەی فرۆشتن.
///
/// English: a completed sale (invoice). It is immutable once created — a sale
/// can only be voided (which returns the stock) so reports stay trustworthy.
class Sale {
  const Sale({
    required this.id,
    required this.items,
    required this.createdAt,
    required this.cashierId,
    required this.cashierName,
    this.discount = 0,
    this.taxPercent = 0,
    this.paidAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.customerName = '',
    this.customerPhone = '',
    this.note = '',
    this.pointsUsed = 0,
    this.pointsDiscount = 0,
    this.pointsEarned = 0,
    this.voidedAt,
    this.voidedBy,
  });

  /// ژمارەی پسووڵە، بۆ نموونە: INV-20260312-0007
  final String id;
  final List<SaleItem> items;
  final DateTime createdAt;
  final String cashierId;
  final String cashierName;
  final double discount;
  final double taxPercent;
  final double paidAmount;
  final PaymentMethod paymentMethod;
  final String customerName;
  final String customerPhone;
  final String note;
  final int pointsUsed;
  final double pointsDiscount;
  final int pointsEarned;
  final DateTime? voidedAt;
  final String? voidedBy;

  bool get isVoided => voidedAt != null;

  /// ئایا ئەم پسووڵەیە ئاڵوگۆڕە (کاڵای گەڕاوەی بە بڕی نەرێنی تێدایە).
  bool get isExchange => items.any((SaleItem item) => item.quantity < 0);

  /// فرۆشتن بە قەرزە یان قەرزی ماوە.
  bool get isCredit => paymentMethod == PaymentMethod.credit || debtAmount > 0;

  /// بڕی قەرزی ماوە لەسەر ئەم پسووڵەیە.
  double get debtAmount {
    if (isVoided) return 0;
    final double diff = total - paidAmount;
    return diff > 0 ? diff : 0;
  }

  /// بڕی پارەی دراو (بە بێ زێدەگی گەڕانەوە).
  double get actualPaid {
    if (paidAmount <= 0) return 0;
    return paidAmount > total ? total : paidAmount;
  }

  /// کۆی دێرەکان پێش داشکاندن و باج.
  double get subtotal =>
      items.fold<double>(0, (double sum, SaleItem item) => sum + item.total);

  /// کۆی تێچووی کاڵاکان (بەپێی نرخی کڕین).
  double get totalCost =>
      items.fold<double>(0, (double sum, SaleItem item) => sum + item.totalCost);

  /// داشکاندن بە سنووردارکردن — نابێت لە کۆی کاڵاکان زیاتر بێت.
  double get safeDiscount {
    if (discount <= 0 || subtotal <= 0) return 0;
    return discount > subtotal ? subtotal : discount;
  }

  /// کۆی گشتی داشکاندن (داشکاندنی ئاسایی + بەهای پۆینتە بەکارهاتووەکان).
  double get totalDiscount {
    if (subtotal <= 0) return 0;
    final double combined = safeDiscount + pointsDiscount;
    return combined > subtotal ? subtotal : combined;
  }

  /// بڕی باج لەسەر بنەمای بەشی دوای داشکاندن.
  double get taxAmount => (subtotal - totalDiscount) * taxPercent / 100;

  double get total => subtotal - totalDiscount + taxAmount;

  double get profit => (subtotal - totalDiscount) - totalCost;

  /// کۆی بڕی کاڵاکان.
  double get itemQuantity =>
      items.fold<double>(0, (double sum, SaleItem item) => sum + item.quantity);

  int get lineCount => items.length;

  double get change {
    final double value = paidAmount - total;
    return value > 0 ? value : 0;
  }

  Sale copyWith({
    List<SaleItem>? items,
    double? discount,
    double? taxPercent,
    double? paidAmount,
    PaymentMethod? paymentMethod,
    String? customerName,
    String? customerPhone,
    String? note,
    int? pointsUsed,
    double? pointsDiscount,
    int? pointsEarned,
    DateTime? voidedAt,
    String? voidedBy,
  }) {
    return Sale(
      id: id,
      items: items ?? this.items,
      createdAt: createdAt,
      cashierId: cashierId,
      cashierName: cashierName,
      discount: discount ?? this.discount,
      taxPercent: taxPercent ?? this.taxPercent,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      note: note ?? this.note,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      pointsDiscount: pointsDiscount ?? this.pointsDiscount,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      voidedAt: voidedAt ?? this.voidedAt,
      voidedBy: voidedBy ?? this.voidedBy,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'items': items.map((SaleItem item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'cashierId': cashierId,
        'cashierName': cashierName,
        'discount': discount,
        'taxPercent': taxPercent,
        'paidAmount': paidAmount,
        'paymentMethod': paymentMethod.name,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'note': note,
        'pointsUsed': pointsUsed,
        'pointsDiscount': pointsDiscount,
        'pointsEarned': pointsEarned,
        'voidedAt': voidedAt?.toIso8601String(),
        'voidedBy': voidedBy,
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        items: (json['items'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic item) =>
                SaleItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        cashierId: json['cashierId'] as String? ?? '',
        cashierName: json['cashierName'] as String? ?? '',
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        paymentMethod: PaymentMethod.fromName(json['paymentMethod'] as String?),
        customerName: json['customerName'] as String? ?? '',
        customerPhone: json['customerPhone'] as String? ?? '',
        note: json['note'] as String? ?? '',
        pointsUsed: (json['pointsUsed'] as num?)?.toInt() ?? 0,
        pointsDiscount: (json['pointsDiscount'] as num?)?.toDouble() ?? 0,
        pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
        voidedAt: json['voidedAt'] == null
            ? null
            : DateTime.tryParse(json['voidedAt'] as String),
        voidedBy: json['voidedBy'] as String?,
      );
}

