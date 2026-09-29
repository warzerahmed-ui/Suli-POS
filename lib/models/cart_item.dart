import 'product.dart';
import 'product_unit.dart';

/// کاڵای ناو سەبەتی فرۆشتن.
///
/// English: a line in the POS cart. Prices/name are copied from the product at
/// the moment it is added, so later product edits never change a running cart.
class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.unitCost,
    required this.quantity,
    this.unit = ProductUnit.piece,
    this.availableStock = 0,
  });

  factory CartItem.fromProduct(Product product, {double quantity = 1}) {
    return CartItem(
      productId: product.id,
      name: product.name,
      unitPrice: product.salePrice,
      unitCost: product.costPrice,
      quantity: quantity,
      unit: product.unit,
      availableStock: product.stock,
    );
  }

  final String productId;
  final String name;
  final ProductUnit unit;
  final double unitPrice;
  final double unitCost;
  final double quantity;

  /// بڕی بەردەست لە کۆگا لە کاتی زیادکردن (بۆ کۆنترۆڵی بڕ).
  final double availableStock;

  double get lineTotal => unitPrice * quantity;

  double get lineCost => unitCost * quantity;

  double get lineProfit => lineTotal - lineCost;

  bool get exceedsStock => quantity > availableStock;

  CartItem copyWith({
    String? productId,
    String? name,
    ProductUnit? unit,
    double? unitPrice,
    double? unitCost,
    double? quantity,
    double? availableStock,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'productId': productId,
        'name': name,
        'unit': unit.name,
        'unitPrice': unitPrice,
        'unitCost': unitCost,
        'quantity': quantity,
        'availableStock': availableStock,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        name: json['name'] as String? ?? '',
        unit: ProductUnit.fromName(json['unit'] as String?),
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        availableStock: (json['availableStock'] as num?)?.toDouble() ?? 0,
      );
}
