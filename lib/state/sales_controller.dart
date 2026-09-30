import 'package:flutter/foundation.dart';

import '../core/app_strings.dart';
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
          sale.cashierName.toLowerCase().contains(needle) ||
          sale.customerName.toLowerCase().contains(needle) ||
          sale.customerPhone.toLowerCase().contains(needle);
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
    String customerName = '',
    String customerPhone = '',
    String note = '',
    int pointsUsed = 0,
    double pointsDiscount = 0,
    int pointsEarned = 0,
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
      customerName: customerName,
      customerPhone: customerPhone,
      note: note,
      pointsUsed: pointsUsed,
      pointsDiscount: pointsDiscount,
      pointsEarned: pointsEarned,
    );

    _sales = <Sale>[sale, ..._sales];
    await _repository.saveSingleSale(sale);
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
    String customerName = '',
    String customerPhone = '',
    String note = '',
    int pointsUsed = 0,
    double pointsDiscount = 0,
    int pointsEarned = 0,
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
      customerName: customerName,
      customerPhone: customerPhone,
      note: note,
      pointsUsed: pointsUsed,
      pointsDiscount: pointsDiscount,
      pointsEarned: pointsEarned,
    );
  }


  /// ئەنجامدانی ئاڵوگۆڕی کاڵا:
  /// کاڵا گەڕاوەکان دەخرێنەوە سەر کۆگا (+).
  /// کاڵا نوێیەکان لە کۆگا کەم دەکرێنەوە (-).
  /// هەژمارکردنی جیاوازی (ساقی و باقی) و تۆمارکردنی وەسڵ.
  Future<Sale> processExchange({
    required List<SaleItem> returnedItems,
    required List<SaleItem> newItems,
    required AppUser cashier,
    required InventoryController inventory,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double? paidAmount,
    String customerName = '',
    String customerPhone = '',
    String note = '',
    DateTime? now,
  }) async {
    final DateTime createdAt = now ?? DateTime.now();

    final List<SaleItem> negativeReturned = returnedItems
        .map(
          (SaleItem item) => SaleItem(
            productId: item.productId,
            name: ' ()',
            unit: item.unit,
            unitPrice: item.unitPrice,
            unitCost: item.unitCost,
            quantity: -item.quantity.abs(),
          ),
        )
        .toList();

    final List<SaleItem> allItems = <SaleItem>[
      ...newItems,
      ...negativeReturned,
    ];

    final int sequence = _repository.nextInvoiceSequence();
    final String id = 'EXC-${Formatters.isoDate(createdAt).replaceAll('-', '')}-${sequence.toString().padLeft(4, '0')}';

    final Sale sale = Sale(
      id: id,
      items: allItems,
      createdAt: createdAt,
      cashierId: cashier.id,
      cashierName: cashier.fullName,
      discount: 0,
      taxPercent: 0,
      paidAmount: paidAmount ?? 0,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerPhone: customerPhone,
      note: note.isNotEmpty ? note : AppStrings.exchangeNoteDefault,
    );

    _sales = <Sale>[sale, ..._sales];
    await _repository.saveSingleSale(sale);
    await inventory.applySaleStock(allItems);
    notifyListeners();
    return sale;
  }

  /// دانەوەی قەرزی پسووڵە (بە تەواوی یان بەشەکی).
  Future<void> settleDebt(String id, {double? amount}) async {
    final int index = _sales.indexWhere((Sale sale) => sale.id == id);
    if (index < 0) return;
    final Sale sale = _sales[index];
    final double newPaid =
        amount != null ? (sale.paidAmount + amount) : sale.total;
    _sales = List<Sale>.from(_sales);
    _sales[index] = sale.copyWith(paidAmount: newPaid);
    await _repository.saveSingleSale(_sales[index]);
    notifyListeners();
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
    await _repository.saveSingleSale(_sales[index]);
    await inventory.restoreStock(sale.items);
    notifyListeners();
  }
}
