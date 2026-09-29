import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../models/app_user.dart';
import '../../models/sale.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/inventory_controller.dart';
import '../../state/sales_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import 'receipt_dialog.dart';

/// دیالۆگی پارەدان و تەواوکردنی فرۆشتن.
/// English: opens the payment dialog, saves the sale, clears the cart and then
/// shows the receipt. Stock is reduced inside `SalesController.checkout`.
Future<void> showCheckoutDialog(BuildContext context) async {
  if (context.read<CartController>().isEmpty) return;

  final Sale? sale = await showDialog<Sale>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => const _CheckoutDialog(),
  );
  if (sale == null || !context.mounted) return;

  AppDialogs.showMessage(context, AppStrings.saleCompleted);
  await showReceiptDialog(context, sale);
}

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog();

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  String? _error;
  bool _busy = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _paidController.text =
          Formatters.number(context.read<CartController>().total);
    }
  }

  @override
  void dispose() {
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _total => context.read<CartController>().total;

  double get _paid {
    if (_method == PaymentMethod.credit) return _total;
    return double.tryParse(_paidController.text.trim().replaceAll(',', '')) ?? 0;
  }

  Future<void> _confirm() async {
    final CartController cart = context.read<CartController>();
    final SalesController sales = context.read<SalesController>();
    final InventoryController inventory = context.read<InventoryController>();
    final AppUser? cashier = context.read<AuthController>().currentUser;
    if (cashier == null) return;

    final double total = cart.total;
    final double paid = _paid;
    if (_method != PaymentMethod.credit && paid < total) {
      setState(() => _error = AppStrings.paidLessThanTotal);
      return;
    }
    if (cart.hasStockIssue) {
      setState(() => _error = AppStrings.insufficientStock);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final Sale sale = await sales.checkout(
      items: cart.items,
      cashier: cashier,
      inventory: inventory,
      discount: cart.safeDiscount,
      taxPercent: cart.taxPercent,
      paymentMethod: _method,
      paidAmount: paid,
      note: _noteController.text.trim(),
    );
    cart.resetAfterSale();
    if (!mounted) return;
    Navigator.of(context).pop(sale);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();
    final double change = _paid - _total;

    return AlertDialog(
      title: const Text(AppStrings.checkoutTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      AppStrings.total,
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      settings.money(_total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.paymentMethod,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PaymentMethod.values.map((PaymentMethod method) {
                  return ChoiceChip(
                    label: Text(method.label),
                    selected: _method == method,
                    onSelected: (_) => setState(() {
                      _method = method;
                      _error = null;
                    }),
                  );
                }).toList(),
              ),
              if (_method != PaymentMethod.credit) ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _paidController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _confirm(),
                  decoration: const InputDecoration(
                    labelText: AppStrings.paidAmount,
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ActionChip(
                      label: const Text(AppStrings.exactAmount),
                      onPressed: () => setState(() => _paidController.text =
                          Formatters.number(_total)),
                    ),
                    ..._roundAmounts(_total).map(
                      (double value) => ActionChip(
                        label: Text(Formatters.number(value)),
                        onPressed: () => setState(
                          () => _paidController.text = Formatters.number(value),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Text(AppStrings.change, style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text(
                      settings.money(change > 0 ? change : 0),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: AppStrings.note,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _confirm,
          icon: const Icon(Icons.check),
          label: const Text(AppStrings.checkout),
        ),
      ],
    );
  }

  /// بڕە خێراکان بۆ پارەدانی نەقدی (خێراتر بۆ کاشێر).
  List<double> _roundAmounts(double total) {
    const List<double> steps = <double>[1000, 5000, 10000, 25000, 50000];
    final List<double> result = <double>[];
    for (final double step in steps) {
      final double rounded = (total / step).ceil() * step;
      if (rounded > total && !result.contains(rounded)) result.add(rounded);
      if (result.length >= 3) break;
    }
    return result;
  }
}
