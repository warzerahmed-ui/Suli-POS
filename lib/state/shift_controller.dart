import 'package:flutter/foundation.dart';
import '../models/shift.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../data/pos_repository.dart';

class ShiftController extends ChangeNotifier {
  ShiftController(this._repository);

  final PosRepository _repository;
  Shift? _currentShift;
  
  Shift? get currentShift => _currentShift;
  bool get isShiftOpen => _currentShift != null && _currentShift!.isOpen;

  void load() {
    _currentShift = _repository.loadCurrentShift();
    notifyListeners();
  }

  Future<void> openShift(String userId, double startingCash) async {
    final shift = Shift(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      openedAt: DateTime.now(),
      openedBy: userId,
      startingCash: startingCash,
    );
    _currentShift = shift;
    await _repository.saveCurrentShift(shift);
    notifyListeners();
  }

  Future<void> closeShift(double actualCash, List<Sale> shiftSales, List<Expense> shiftExpenses, {String? note}) async {
    if (_currentShift == null) return;
    
    double cashSales = 0;
    for (final sale in shiftSales) {
      if (sale.paymentMethod == PaymentMethod.cash && !sale.isVoided) {
        cashSales += sale.actualPaid;
      }
    }
    
    double totalExpenses = 0;
    for (final exp in shiftExpenses) {
      totalExpenses += exp.amount;
    }

    final expected = _currentShift!.startingCash + cashSales - totalExpenses;

    final closedShift = _currentShift!.copyWith(
      closedAt: DateTime.now(),
      actualCash: actualCash,
      expectedCash: expected,
      note: note,
    );

    await _repository.saveShiftHistory(closedShift);
    await _repository.clearCurrentShift();
    _currentShift = null;
    notifyListeners();
  }
}