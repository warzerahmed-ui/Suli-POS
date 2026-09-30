import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/sale.dart';
import '../state/auth_controller.dart';
import '../state/expenses_controller.dart';
import '../state/sales_controller.dart';
import '../state/shift_controller.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final TextEditingController _startingCashCtrl = TextEditingController();
  final TextEditingController _actualCashCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _startingCashCtrl.dispose();
    _actualCashCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftCtrl = context.watch<ShiftController>();
    final authCtrl = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.shift),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: shiftCtrl.isShiftOpen
                    ? _buildCloseShift(context, shiftCtrl)
                    : _buildOpenShift(context, shiftCtrl, authCtrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenShift(BuildContext context, ShiftController shiftCtrl, AuthController authCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_open, size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          AppStrings.noOpenShift,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _startingCashCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: AppStrings.startingCash,
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
          icon: const Icon(Icons.play_arrow),
          label: const Text(AppStrings.openShift, style: TextStyle(fontSize: 18)),
          onPressed: () {
            final double amount = double.tryParse(_startingCashCtrl.text) ?? 0;
            final user = authCtrl.currentUser;
            if (user != null) {
              shiftCtrl.openShift(user.id, amount);
              _startingCashCtrl.clear();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCloseShift(BuildContext context, ShiftController shiftCtrl) {
    final shift = shiftCtrl.currentShift!;
    final salesCtrl = context.watch<SalesController>();
    final expensesCtrl = context.watch<ExpensesController>();

    final shiftSales = salesCtrl.sales.where((s) => s.createdAt.isAfter(shift.openedAt)).toList();
    final shiftExpenses = expensesCtrl.expenses.where((e) => e.createdAt.isAfter(shift.openedAt)).toList();

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

    final expectedCash = shift.startingCash + cashSales - totalExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.point_of_sale, size: 64, color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          "${AppStrings.shiftAlreadyOpen} ${shift.openedBy}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "${AppStrings.openedAt}: ${shift.openedAt.toString().substring(0, 16)}",
          textAlign: TextAlign.center,
        ),
        const Divider(height: 32),
        
        _buildSummaryRow(AppStrings.startingCash, shift.startingCash),
        _buildSummaryRow(AppStrings.shiftCashSales, cashSales),
        _buildSummaryRow(AppStrings.shiftExpenses, -totalExpenses, isNegative: true),
        const Divider(),
        _buildSummaryRow(AppStrings.expectedCash, expectedCash, isTotal: true),
        
        const SizedBox(height: 24),
        TextField(
          controller: _actualCashCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: AppStrings.actualCash,
            prefixIcon: Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 16),
        
        Builder(builder: (context) {
          final actual = double.tryParse(_actualCashCtrl.text) ?? 0;
          final diff = actual - expectedCash;
          final color = diff < 0 ? Colors.red : (diff > 0 ? Colors.green : Colors.grey);
          return Text(
            "${AppStrings.shiftDifference}: ${diff.toStringAsFixed(0)}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          );
        }),
        
        const SizedBox(height: 16),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: AppStrings.shiftNote,
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
          ),
        ),
        
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          icon: const Icon(Icons.stop),
          label: const Text(AppStrings.printZReport, style: TextStyle(fontSize: 18)),
          onPressed: () {
            final double actual = double.tryParse(_actualCashCtrl.text) ?? 0;
            shiftCtrl.closeShift(
              actual,
              shiftSales,
              shiftExpenses,
              note: _noteCtrl.text,
            );
            _actualCashCtrl.clear();
            _noteCtrl.clear();
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            amount.toStringAsFixed(0),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : (isTotal ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}