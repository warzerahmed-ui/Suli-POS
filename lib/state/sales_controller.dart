import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../data/pos_repository.dart';
import '../models/analytics.dart';
import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import 'inventory_controller.dart';

/// کۆنترۆڵەری پسووڵەکان: تەواوکردنی فرۆشتن، هەڵوەشاندنەوە و ڕاپۆرت.
///
/// English: owns the invoice history plus every aggregate the dashboard and the
/// reports screen need. Voiding a sale restores the stock it consumed.
class SalesController extends ChangeNotifier {
  SalesController(this._repository);

  final PosRepository _repository;

  List<Sale> _sales = <Sale>[];

  /// پسووڵەکان — نوێترین سەرەتا.
  List<Sale> get sales => List<Sale>.unmodifiable(_sales);

  List<Sale> get activeSales =>
      _sales.where((Sale sale) => !sale.isVoided).toList();

  void load() {
    final List<Sale> loaded = _repository.loadSales()
      ..sort((Sale a, Sale b) => b.createdAt.compareTo(a.createdAt));
    _sales = loaded;
    notifyListeners();
  }

  Sale? saleById(String id) {
    for (final Sale sale in _sales) {
      if (sale.id == id) return sale;
    }
    return null;
  }

  List<Sale> recent({int limit = 5}) => _sales.take(limit).toList();

  List<Sale> salesInRange(
    DateTime from,
    DateTime to, {
    bool includeVoided = false,
  }) {
    final DateTime start = Formatters.startOfDay(from);
    final DateTime end = Formatters.endOfDay(to);
    return _sales.where((Sale sale) {
      if (!includeVoided && sale.isVoided) return false;
      return !sale.createdAt.isBefore(start) && !sale.createdAt.isAfter(end);
    }).toList();
  }

  List<Sale> todaysSales({DateTime? now}) {
    final DateTime today = now ?? DateTime.now();
    return _sales
        .where((Sale sale) =>
            !sale.isVoided && Formatters.isSameDay(sale.createdAt, today))
        .toList();
  }

  SaleSummary get todaySummary => SaleSummary.fromSales(todaysSales());

  SaleSummary summaryOf(Iterable<Sale> sales) => SaleSummary.fromSales(sales);

  List<DailyPoint> dailyPoints({int days = 7, DateTime? now}) {
    final DateTime today = Formatters.startOfDay(now ?? DateTime.now());
    return DailyPoint.forRange(
      _sales,
      from: today.subtract(Duration(days: days - 1)),
      to: today,
    );
  }

  /// گەڕان لە پسووڵەکان بە ژمارە یان ناوی کاشێر.
  List<Sale> search(String query, {List<Sale>? source}) {
    final String needle = query.trim().toLowerCase();
    final List<Sale> list = source ?? _sales;
    if (needle.isEmpty) return list;
    return list.where((Sale sale) {
      return sale.id.toLowerCase().contains(needle) ||
          sale.cashierName.toLowerCase().contains(needle);
    }).toList();
  }

  /// تەواوکردنی فرۆشتنێکی نوێ — پسووڵە دروست دەکات و کۆگا کەم دەکاتەوە.
  Future<Sale> checkout({
    required List<CartItem> items,
    required AppUser cashier,
    required InventoryController inventory,
    double discount = 0,
    double taxPercent = 0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double? paidAmount,
    String note = '',
    DateTime? now,
  }) async {
    final DateTime createdAt = now ?? DateTime.now();
    final Sale sale = buildSale(
      items: items,
      cashier: cashier,
      createdAt: createdAt,
      discount: discount,
      taxPercent: taxPercent,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      note: note,
    );

    _sales = <Sale>[sale, ..._sales];
    await _repository.saveSales(_sales);
    await inventory.applySaleStock(sale.items);
    notifyListeners();
    return sale;
  }

  /// دروستکردنی پسووڵە بەبێ پاشەکەوتکردن (بۆ پشکنین).
  Sale buildSale({
    required List<CartItem> items,
    required AppUser cashier,
    required DateTime createdAt,
    double discount = 0,
    double taxPercent = 0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double? paidAmount,
    String note = '',
  }) {
    final int sequence = _repository.nextInvoiceSequence();
    final String id = 'INV-${Formatters.isoDate(createdAt).replaceAll('-', '')}'
        '-${sequence.toString().padLeft(4, '0')}';
    return Sale(
      id: id,
      items: items.map(SaleItem.fromCartItem).toList(growable: false),
      createdAt: createdAt,
      cashierId: cashier.id,
      cashierName: cashier.fullName,
      discount: discount,
      taxPercent: taxPercent,
      paidAmount: paidAmount ?? 0,
      paymentMethod: paymentMethod,
      note: note,
    );
  }

  /// هەڵوەشاندنەوەی پسووڵە و گەڕاندنەوەی کاڵاکان بۆ کۆگا.
  Future<void> voidSale(
    String id, {
    required AppUser user,
    required InventoryController inventory,
  }) async {
    final int index = _sales.indexWhere((Sale sale) => sale.id == id);
    if (index < 0) return;
    final Sale sale = _sales[index];
    if (sale.isVoided) return;

    _sales = List<Sale>.from(_sales);
    _sales[index] = sale.copyWith(
      voidedAt: DateTime.now(),
      voidedBy: user.fullName,
    );
    await _repository.saveSales(_sales);
    await inventory.restoreStock(sale.items);
    notifyListeners();
  }
}
