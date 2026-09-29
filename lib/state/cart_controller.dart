import 'package:flutter/foundation.dart';

import '../core/app_strings.dart';
import '../data/pos_repository.dart';
import '../models/cart_item.dart';
import '../models/held_cart.dart';
import '../models/product.dart';

/// کۆنترۆڵەری سەبەتی فرۆشتن (POS).
///
/// English: the running cart, its totals (discount + tax) and the parked carts.
/// Every mutation returns an error message (or `null`) so the UI can show a
/// snackbar when stock is not enough.
class CartController extends ChangeNotifier {
  CartController(this._repository);

  final PosRepository _repository;

  final List<CartItem> _items = <CartItem>[];
  List<HeldCart> _heldCarts = <HeldCart>[];
  double _discount = 0;
  double _taxPercent = 0;

  List<CartItem> get items => List<CartItem>.unmodifiable(_items);

  List<HeldCart> get heldCarts => List<HeldCart>.unmodifiable(_heldCarts);

  bool get isEmpty => _items.isEmpty;

  int get lineCount => _items.length;

  double get itemQuantity =>
      _items.fold<double>(0, (double sum, CartItem item) => sum + item.quantity);

  double get discount => _discount;

  double get taxPercent => _taxPercent;

  double get subtotal =>
      _items.fold<double>(0, (double sum, CartItem item) => sum + item.lineTotal);

  double get safeDiscount {
    if (_discount <= 0) return 0;
    return _discount > subtotal ? subtotal : _discount;
  }

  double get taxAmount => (subtotal - safeDiscount) * _taxPercent / 100;

  double get total => subtotal - safeDiscount + taxAmount;

  double get estimatedProfit =>
      (subtotal - safeDiscount) -
      _items.fold<double>(0, (double sum, CartItem item) => sum + item.lineCost);

  /// کاڵایەک لە سەبەتە زیاترە لە بڕی کۆگا.
  bool get hasStockIssue => _items.any((CartItem item) => item.exceedsStock);

  List<String> get stockIssueNames => _items
      .where((CartItem item) => item.exceedsStock)
      .map((CartItem item) => item.name)
      .toList();

  void load() {
    _heldCarts = _repository.loadHeldCarts();
    notifyListeners();
  }

  void setTaxPercent(double value) {
    if (_taxPercent == value) return;
    _taxPercent = value;
    notifyListeners();
  }

  void setDiscount(double value) {
    final double next = value < 0 ? 0 : value;
    if (_discount == next) return;
    _discount = next;
    notifyListeners();
  }

  double quantityOf(String productId) {
    for (final CartItem item in _items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  bool contains(String productId) => quantityOf(productId) > 0;

  /// زیادکردنی کاڵا بۆ سەبەتە.
  String? addProduct(Product product, {double quantity = 1}) {
    if (product.isOutOfStock) return AppStrings.outOfStock;
    final int index =
        _items.indexWhere((CartItem item) => item.productId == product.id);
    final double amount = quantity <= 0 ? 1 : quantity;
    if (index < 0) {
      if (amount > product.stock) return AppStrings.insufficientStock;
      _items.add(CartItem.fromProduct(product, quantity: amount));
      notifyListeners();
      return null;
    }
    return _setQuantity(index, _items[index].quantity + amount);
  }

  String? increaseQuantity(String productId) {
    final int index = _indexOf(productId);
    if (index < 0) return null;
    final CartItem item = _items[index];
    final double step = item.unit.allowsFractions ? 0.5 : 1;
    return _setQuantity(index, item.quantity + step);
  }

  String? decreaseQuantity(String productId) {
    final int index = _indexOf(productId);
    if (index < 0) return null;
    final CartItem item = _items[index];
    final double step = item.unit.allowsFractions ? 0.5 : 1;
    return _setQuantity(index, item.quantity - step);
  }

  String? setQuantity(String productId, double quantity) {
    final int index = _indexOf(productId);
    if (index < 0) return null;
    return _setQuantity(index, quantity);
  }

  void removeItem(String productId) {
    _items.removeWhere((CartItem item) => item.productId == productId);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty && _discount == 0) return;
    _items.clear();
    _discount = 0;
    notifyListeners();
  }

  /// بانگهێشتکردنەوەی سەبەتە دوای تەواوبوونی فرۆشتن.
  void resetAfterSale() {
    _items.clear();
    _discount = 0;
    notifyListeners();
  }

  /// هەڵواسینی سەبەتەی ئێستا بۆ کڕیارێکی دیکە.
  Future<void> holdCart({String label = ''}) async {
    if (_items.isEmpty) return;
    final HeldCart held = HeldCart(
      id: 'held-${DateTime.now().microsecondsSinceEpoch}',
      label: label.trim().isEmpty ? AppStrings.cart : label.trim(),
      createdAt: DateTime.now(),
      items: List<CartItem>.from(_items),
      discount: _discount,
    );
    _heldCarts = <HeldCart>[held, ..._heldCarts];
    _items.clear();
    _discount = 0;
    await _repository.saveHeldCarts(_heldCarts);
    notifyListeners();
  }

  Future<void> resumeHeldCart(String id) async {
    final int index =
        _heldCarts.indexWhere((HeldCart cart) => cart.id == id);
    if (index < 0) return;
    final HeldCart held = _heldCarts[index];
    _items
      ..clear()
      ..addAll(held.items);
    _discount = held.discount;
    _heldCarts = _heldCarts.where((HeldCart cart) => cart.id != id).toList();
    await _repository.saveHeldCarts(_heldCarts);
    notifyListeners();
  }

  Future<void> deleteHeldCart(String id) async {
    _heldCarts = _heldCarts.where((HeldCart cart) => cart.id != id).toList();
    await _repository.saveHeldCarts(_heldCarts);
    notifyListeners();
  }

  int _indexOf(String productId) =>
      _items.indexWhere((CartItem item) => item.productId == productId);

  String? _setQuantity(int index, double quantity) {
    if (quantity <= 0) {
      _items.removeAt(index);
      notifyListeners();
      return null;
    }
    final CartItem item = _items[index];
    if (quantity > item.availableStock) return AppStrings.insufficientStock;
    _items[index] = item.copyWith(quantity: quantity);
    notifyListeners();
    return null;
  }
}
