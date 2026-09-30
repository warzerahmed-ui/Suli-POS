import 'package:flutter/foundation.dart' hide Category;

import '../data/pos_repository.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sale.dart';

/// کۆنترۆڵەری کۆگا: کاڵاکان، پۆلەکان و بڕی کۆگا.
///
/// English: the product catalogue. It also moves stock when a sale is completed
/// or voided, and feeds the low-stock alerts on the dashboard.
class InventoryController extends ChangeNotifier {
  InventoryController(this._repository);

  final PosRepository _repository;

  List<Product> _products = <Product>[];
  List<Category> _categories = <Category>[];

  List<Product> get products => List<Product>.unmodifiable(_products);

  List<Category> get categories => List<Category>.unmodifiable(_categories);

  /// پۆلەکان لەگەڵ پۆلی «بێ پۆل» (بۆ فلتەر و فۆرمەکان).
  List<Category> get categoriesWithUncategorized =>
      <Category>[Category.uncategorized, ..._categories];

  int get productCount => _products.length;

  int get activeProductCount =>
      _products.where((Product product) => product.isActive).length;

  double get inventoryValue => _products.fold<double>(
        0,
        (double sum, Product product) => sum + product.stockValue,
      );

  double get retailInventoryValue => _products.fold<double>(
        0,
        (double sum, Product product) => sum + product.salePrice * product.stock,
      );

  /// کاڵاکانی کەم لە کۆگا (کەمترین بڕ سەرەتا).
  List<Product> get lowStockProducts {
    final List<Product> list = _products
        .where((Product product) => product.isActive && product.needsReorder)
        .toList()
      ..sort((Product a, Product b) => a.stock.compareTo(b.stock));
    return list;
  }

  void load() {
    _products = _repository.loadProducts();
    _categories = _repository.loadCategories();
    notifyListeners();
  }

  Category categoryById(String id) {
    for (final Category category in _categories) {
      if (category.id == id) return category;
    }
    return Category.uncategorized;
  }

  Product? productById(String id) {
    for (final Product product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Product? productByBarcode(String barcode) {
    final String code = barcode.trim();
    if (code.isEmpty) return null;
    for (final Product product in _products) {
      if (product.isActive && product.barcode == code) return product;
    }
    return null;
  }

  /// گەڕان بە ناو یان بارکۆد، لەگەڵ فلتەری پۆل.
  List<Product> search({
    String query = '',
    String categoryId = '',
    bool includeInactive = false,
    bool onlyAvailable = false,
  }) {
    final String needle = query.trim().toLowerCase();
    return _products.where((Product product) {
      if (!includeInactive && !product.isActive) return false;
      if (onlyAvailable && product.isOutOfStock) return false;
      if (categoryId.isNotEmpty && product.categoryId != categoryId) {
        return false;
      }
      if (needle.isEmpty) return true;
      return product.name.toLowerCase().contains(needle) ||
          product.barcode.toLowerCase().contains(needle);
    }).toList();
  }

  int productCountInCategory(String id) =>
      _products.where((Product product) => product.categoryId == id).length;

  Future<void> upsertProduct(Product product) async {
    final int index =
        _products.indexWhere((Product item) => item.id == product.id);
    if (index < 0) {
      _products = <Product>[..._products, product];
    } else {
      _products = _products
          .map((Product item) => item.id == product.id ? product : item)
          .toList();
    }
    await _repository.saveSingleProduct(product);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    _products = _products.where((Product product) => product.id != id).toList();
    await _repository.deleteSingleProduct(id);
    notifyListeners();
  }

  Future<void> upsertCategory(Category category) async {
    final int index =
        _categories.indexWhere((Category item) => item.id == category.id);
    if (index < 0) {
      _categories = <Category>[..._categories, category];
    } else {
      _categories = _categories
          .map((Category item) => item.id == category.id ? category : item)
          .toList();
    }
    await _repository.saveSingleCategory(category);
    notifyListeners();
  }

  /// سڕینەوەی پۆل — کاڵاکانی دەگوازرێنەوە بۆ پۆلی «بێ پۆل».
  Future<void> deleteCategory(String id) async {
    _categories =
        _categories.where((Category category) => category.id != id).toList();
    _products = _products
        .map((Product product) => product.categoryId == id
            ? product.copyWith(categoryId: '')
            : product)
        .toList();
    await _repository.deleteSingleCategory(id);
    notifyListeners();
  }

  /// کەمکردنەوەی کۆگا کاتێک فرۆشتنێک تەواو دەبێت.
  Future<void> applySaleStock(List<SaleItem> items) =>
      _applyStock(items, restore: false);

  /// گەڕاندنەوەی کۆگا کاتێک پسووڵەیەک هەڵدەوەشێنرێتەوە.
  Future<void> restoreStock(List<SaleItem> items) =>
      _applyStock(items, restore: true);

  Future<void> adjustStock(String productId, double delta) async {
    final Product? product = productById(productId);
    if (product == null) return;
    final double updated = product.stock + delta;
    await upsertProduct(product.copyWith(stock: updated < 0 ? 0 : updated));
  }

  Future<void> _applyStock(List<SaleItem> items, {required bool restore}) async {
    if (items.isEmpty) return;
    final Map<String, double> deltas = <String, double>{};
    final Map<String, double> newStocks = <String, double>{};
    for (final SaleItem item in items) {
      final double value = restore ? item.quantity : -item.quantity;
      deltas[item.productId] = (deltas[item.productId] ?? 0) + value;
    }
    _products = _products.map((Product product) {
      final double? delta = deltas[product.id];
      if (delta == null) return product;
      final double stock = product.stock + delta;
      final double clamped = stock < 0 ? 0 : stock;
      newStocks[product.id] = clamped;
      return product.copyWith(stock: clamped);
    }).toList();
    await _repository.updateProductsStock(newStocks);
    notifyListeners();
  }

  /// جێگۆڕکێی هەموو کاڵا و پۆلەکان (بۆ بارکردنەوەی داتای نموونە یان ڕێسێت).
  Future<void> replaceAll({
    required List<Product> products,
    required List<Category> categories,
  }) async {
    _products = products;
    _categories = categories;
    await _repository.saveProducts(_products);
    await _repository.saveCategories(_categories);
    notifyListeners();
  }
}
