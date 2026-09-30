import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../data/pos_repository.dart';

class ExpensesController extends ChangeNotifier {
  ExpensesController(this._repository);

  final PosRepository _repository;
  List<Expense> _expenses = [];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  void load() {
    _expenses = _repository.loadExpenses();
    // Sort by date descending
    _expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void addExpense(Expense expense) {
    _expenses = [expense, ..._expenses];
    _repository.saveSingleExpense(expense);
    notifyListeners();
  }

  void deleteExpense(String id) {
    _expenses = _expenses.where((e) => e.id != id).toList();
    _repository.deleteSingleExpense(id);
    notifyListeners();
  }

  double get todayExpenses {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.createdAt.year == now.year &&
              e.createdAt.month == now.month &&
              e.createdAt.day == now.day,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}
