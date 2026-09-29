import 'cart_item.dart';

/// سەبەتەیەکی هەڵواسراو (کڕیار کاڵایەکی لەبیرچووە، سەبەتەکە دەپارێزرێت).
/// English: a parked cart so a cashier can serve another customer and come back.
class HeldCart {
  const HeldCart({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.items,
    this.discount = 0,
  });

  final String id;
  final String label;
  final DateTime createdAt;
  final List<CartItem> items;
  final double discount;

  int get lineCount => items.length;

  double get itemQuantity =>
      items.fold<double>(0, (double sum, CartItem item) => sum + item.quantity);

  double get subtotal =>
      items.fold<double>(0, (double sum, CartItem item) => sum + item.lineTotal);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((CartItem item) => item.toJson()).toList(),
        'discount': discount,
      };

  factory HeldCart.fromJson(Map<String, dynamic> json) => HeldCart(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        items: (json['items'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic item) =>
                CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
      );
}
