import 'product_unit.dart';

/// کاڵایەکی فرۆشگا (ناو، بارکۆد، نرخ، کۆگا ...).
/// English: a sellable product with pricing + stock information.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.costPrice,
    this.barcode = '',
    this.categoryId = '',
    this.unit = ProductUnit.piece,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String barcode;
  final String categoryId;
  final ProductUnit unit;
  final double costPrice;
  final double salePrice;
  final double stock;
  final double lowStockThreshold;
  final bool isActive;
  final DateTime? createdAt;

  /// قازانجی هەر یەکەیەک.
  double get unitProfit => salePrice - costPrice;

  /// ڕێژەی قازانج بە سەدە.
  double get profitMargin =>
      salePrice <= 0 ? 0 : (unitProfit / salePrice) * 100;

  /// بەهای کۆگای ئەم کاڵایە بەپێی نرخی کڕین.
  double get stockValue => costPrice * stock;

  bool get isOutOfStock => stock <= 0;

  bool get isLowStock => !isOutOfStock && stock <= lowStockThreshold;

  bool get needsReorder => stock <= lowStockThreshold;

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    String? categoryId,
    ProductUnit? unit,
    double? costPrice,
    double? salePrice,
    double? stock,
    double? lowStockThreshold,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'barcode': barcode,
        'categoryId': categoryId,
        'unit': unit.name,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'stock': stock,
        'lowStockThreshold': lowStockThreshold,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        unit: ProductUnit.fromName(json['unit'] as String?),
        costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
        salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toDouble() ?? 0,
        lowStockThreshold:
            (json['lowStockThreshold'] as num?)?.toDouble() ?? 5,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
      );
}
