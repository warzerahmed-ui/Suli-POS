import 'package:flutter/foundation.dart';

import '../data/pos_repository.dart';
import '../models/customer.dart';

/// کۆنترۆڵەری کڕیاران و سیستەمی پۆینتی وەفاداری (Loyalty Points).
class CustomerController extends ChangeNotifier {
  CustomerController(this._repository);

  final PosRepository _repository;

  List<Customer> _customers = <Customer>[];

  List<Customer> get customers => List<Customer>.unmodifiable(_customers);

  int get customerCount => _customers.length;

  /// کۆی هەموو ئەو پۆینتانەی لە دەستی کڕیاراندان
  int get totalActivePoints => _customers.fold<int>(
        0,
        (int sum, Customer c) => sum + c.points,
      );

  void load() {
    _customers = _repository.loadCustomers()
      ..sort((Customer a, Customer b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Customer? customerById(String id) {
    for (final Customer c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Customer? customerByPhone(String phone) {
    final String clean = phone.trim().replaceAll(' ', '');
    if (clean.isEmpty) return null;
    for (final Customer c in _customers) {
      if (c.phone.replaceAll(' ', '') == clean) return c;
    }
    return null;
  }

  List<Customer> search(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return _customers;
    return _customers.where((Customer c) {
      return c.name.toLowerCase().contains(needle) ||
          c.phone.contains(needle) ||
          c.note.toLowerCase().contains(needle);
    }).toList();
  }

  /// پاشەکەوتکردن یان دەستکاریکردنی کڕیار
  Future<void> upsertCustomer(Customer customer) async {
    final int index = _customers.indexWhere((Customer c) => c.id == customer.id);
    if (index >= 0) {
      _customers = List<Customer>.from(_customers);
      _customers[index] = customer;
    } else {
      _customers = <Customer>[customer, ..._customers];
    }
    await _repository.saveSingleCustomer(customer);
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    _customers = _customers.where((Customer c) => c.id != id).toList();
    await _repository.deleteSingleCustomer(id);
    notifyListeners();
  }

  /// دۆزینەوە یان دروستکردنی کڕیار بە شێوەی خودکار لە کاتی فرۆشتن
  Future<Customer?> findOrCreate({
    required String name,
    required String phone,
  }) async {
    final String cleanName = name.trim();
    final String cleanPhone = phone.trim();
    if (cleanName.isEmpty && cleanPhone.isEmpty) return null;

    Customer? found;
    if (cleanPhone.isNotEmpty) {
      found = customerByPhone(cleanPhone);
    }
    if (found == null && cleanName.isNotEmpty) {
      for (final Customer c in _customers) {
        if (c.name.trim().toLowerCase() == cleanName.toLowerCase()) {
          found = c;
          break;
        }
      }
    }

    if (found != null) {
      // ئەگەر ناوی نوێ یان ژمارەی نوێی هەبوو نوێی بکەرەوە
      if ((cleanName.isNotEmpty && found.name != cleanName) ||
          (cleanPhone.isNotEmpty && found.phone != cleanPhone)) {
        final Customer updated = found.copyWith(
          name: cleanName.isNotEmpty ? cleanName : found.name,
          phone: cleanPhone.isNotEmpty ? cleanPhone : found.phone,
          updatedAt: DateTime.now(),
        );
        await upsertCustomer(updated);
        return updated;
      }
      return found;
    }

    // کڕیاری نوێ دروست بکە
    final Customer newCustomer = Customer(
      id: 'cust-${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName.isNotEmpty ? cleanName : 'کڕیار',
      phone: cleanPhone,
      points: 0,
      totalSpent: 0,
      totalPointsEarned: 0,
      totalPointsUsed: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await upsertCustomer(newCustomer);
    return newCustomer;
  }

  /// بەخشینی پۆینتی نوێ دوای کڕین
  Future<int> earnPoints({
    required String customerId,
    required double spentAmount,
    required double pointsPerAmount,
  }) async {
    if (pointsPerAmount <= 0 || spentAmount <= 0) return 0;
    final Customer? customer = customerById(customerId);
    if (customer == null) return 0;

    final int earned = (spentAmount / pointsPerAmount).floor();
    if (earned <= 0) {
      // تەنها بڕی خەرجکراو نوێ بکەرەوە
      final Customer updated = customer.copyWith(
        totalSpent: customer.totalSpent + spentAmount,
        updatedAt: DateTime.now(),
      );
      await upsertCustomer(updated);
      return 0;
    }

    final Customer updated = customer.copyWith(
      points: customer.points + earned,
      totalSpent: customer.totalSpent + spentAmount,
      totalPointsEarned: customer.totalPointsEarned + earned,
      updatedAt: DateTime.now(),
    );

    await upsertCustomer(updated);
    return earned;
  }

  /// بەکارهێنانی پۆینت بۆ داشکاندن لە کاتی کڕین
  Future<double> redeemPoints({
    required String customerId,
    required int pointsToUse,
    required double amountPerPoint,
  }) async {
    if (pointsToUse <= 0 || amountPerPoint <= 0) return 0;
    final Customer? customer = customerById(customerId);
    if (customer == null || customer.points < pointsToUse) return 0;

    final double discount = pointsToUse * amountPerPoint;
    final Customer updated = customer.copyWith(
      points: customer.points - pointsToUse,
      totalPointsUsed: customer.totalPointsUsed + pointsToUse,
      updatedAt: DateTime.now(),
    );

    await upsertCustomer(updated);
    return discount;
  }

  /// دەستکاریکردنی پۆینت بە دەست (دیاری یان ڕاستکردنەوە)
  Future<void> manualAdjustPoints(
    String customerId,
    int delta, {
    String reason = '',
  }) async {
    final Customer? customer = customerById(customerId);
    if (customer == null) return;

    final int newPoints = customer.points + delta;
    final int clampedPoints = newPoints < 0 ? 0 : newPoints;

    final Customer updated = customer.copyWith(
      points: clampedPoints,
      note: reason.isNotEmpty
          ? '${customer.note}\n[${DateTime.now().toString().substring(0, 10)}] دەستکاری پۆینت: ${delta > 0 ? "+$delta" : "$delta"} ($reason)'
          : customer.note,
      updatedAt: DateTime.now(),
    );

    await upsertCustomer(updated);
  }
}

