import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../models/app_user.dart';
import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/customer_controller.dart';
import '../../state/inventory_controller.dart';
import '../../state/sales_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import 'receipt_dialog.dart';

/// دیالۆگی پارەدان و تەواوکردنی فرۆشتن لەگەڵ سیستەمی پۆینتی وەفاداری.
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
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  String? _error;
  bool _busy = false;
  bool _initialised = false;

  Customer? _matchedCustomer;
  bool _usePoints = false;
  int _pointsToRedeem = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _paidController.text = Formatters.number(
        context.read<CartController>().total,
      );
    }
  }

  @override
  void dispose() {
    _paidController.dispose();
    _noteController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  double get _cartTotal => context.read<CartController>().total;

  double get _pointsDiscount {
    if (!_usePoints || _matchedCustomer == null || _pointsToRedeem <= 0)
      return 0;
    final SettingsController settings = context.read<SettingsController>();
    return _pointsToRedeem * settings.settings.amountPerPoint;
  }

  double get _payableTotal {
    final double net = _cartTotal - _pointsDiscount;
    return net > 0 ? net : 0;
  }

  double get _paid =>
      double.tryParse(_paidController.text.trim().replaceAll(',', '')) ?? 0;

  double get _remainingDebt =>
      (_payableTotal - _paid) > 0 ? (_payableTotal - _paid) : 0;

  int _calculatePotentialEarnedPoints() {
    final SettingsController settings = context.read<SettingsController>();
    if (!settings.settings.pointsEnabled ||
        settings.settings.pointsPerAmount <= 0) {
      return 0;
    }
    return (_payableTotal / settings.settings.pointsPerAmount).floor();
  }

  void _onCustomerPhoneOrNameChanged() {
    final CustomerController custCtrl = context.read<CustomerController>();
    final String phone = _customerPhoneController.text.trim();
    final String name = _customerNameController.text.trim();

    Customer? match;
    if (phone.isNotEmpty) {
      match = custCtrl.customerByPhone(phone);
    }
    if (match == null && name.isNotEmpty) {
      for (final Customer c in custCtrl.customers) {
        if (c.name.trim().toLowerCase() == name.toLowerCase()) {
          match = c;
          break;
        }
      }
    }

    setState(() {
      _matchedCustomer = match;
      if (match != null) {
        if (_customerNameController.text.isEmpty && match.name.isNotEmpty) {
          _customerNameController.text = match.name;
        }
        if (_customerPhoneController.text.isEmpty && match.phone.isNotEmpty) {
          _customerPhoneController.text = match.phone;
        }
      }

      if (match == null || match.points <= 0) {
        _usePoints = false;
        _pointsToRedeem = 0;
        _pointsController.clear();
      } else if (_usePoints) {
        _clampPoints(match);
      }
      _syncPaidWithPayable();
    });
  }

  void _clampPoints(Customer customer) {
    final SettingsController settings = context.read<SettingsController>();
    final double appPerPt = settings.settings.amountPerPoint;
    final int maxByBill = appPerPt > 0
        ? (_cartTotal / appPerPt).floor()
        : customer.points;
    final int maxAllowed = customer.points < maxByBill
        ? customer.points
        : maxByBill;

    if (_pointsToRedeem > maxAllowed) {
      _pointsToRedeem = maxAllowed;
      _pointsController.text = _pointsToRedeem.toString();
    }
  }

  void _toggleUsePoints(bool value) {
    if (_matchedCustomer == null || _matchedCustomer!.points <= 0) return;
    setState(() {
      _usePoints = value;
      if (value) {
        final SettingsController settings = context.read<SettingsController>();
        final double appPerPt = settings.settings.amountPerPoint;
        final int maxByBill = appPerPt > 0
            ? (_cartTotal / appPerPt).floor()
            : _matchedCustomer!.points;
        _pointsToRedeem = _matchedCustomer!.points < maxByBill
            ? _matchedCustomer!.points
            : maxByBill;
        _pointsController.text = _pointsToRedeem.toString();
      } else {
        _pointsToRedeem = 0;
        _pointsController.clear();
      }
      _syncPaidWithPayable();
    });
  }

  void _syncPaidWithPayable() {
    if (_method != PaymentMethod.credit) {
      _paidController.text = Formatters.number(_payableTotal);
    }
  }

  Future<void> _pickCustomerDialog() async {
    final CustomerController custCtrl = context.read<CustomerController>();

    final Customer? selected = await showDialog<Customer>(
      context: context,
      builder: (BuildContext ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final List<Customer> filtered = custCtrl.search(filter);
            return AlertDialog(
              title: const Text('دیاریکردنی کڕیار'),
              content: SizedBox(
                width: 380,
                height: 350,
                child: Column(
                  children: <Widget>[
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'گەڕان بەپێی ناو یان ژمارە مۆبایل...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (String q) => setModalState(() => filter = q),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('هیچ کڕیارێک نەدۆزرایەوە'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (BuildContext _, int i) {
                                final Customer c = filtered[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade100,
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    c.phone.isNotEmpty ? c.phone : 'بێ ژمارە',
                                  ),
                                  trailing: Chip(
                                    backgroundColor: Colors.amber.shade50,
                                    label: Text(
                                      '${c.points} پۆینت',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  onTap: () => Navigator.of(ctx).pop(c),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('داخستن'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      _customerNameController.text = selected.name;
      _customerPhoneController.text = selected.phone;
      _onCustomerPhoneOrNameChanged();
    }
  }

  Future<void> _confirm() async {
    final CartController cart = context.read<CartController>();
    final SalesController sales = context.read<SalesController>();
    final InventoryController inventory = context.read<InventoryController>();
    final CustomerController customerController = context
        .read<CustomerController>();
    final SettingsController settings = context.read<SettingsController>();
    final AppUser? cashier = context.read<AuthController>().currentUser;
    if (cashier == null) return;

    final double payable = _payableTotal;
    final double paid = _paid;
    if (_method != PaymentMethod.credit && paid < payable) {
      setState(() => _error = AppStrings.paidLessThanTotal);
      return;
    }
    if (_method == PaymentMethod.credit &&
        _customerNameController.text.trim().isEmpty) {
      setState(() => _error = 'تکایە ناوی کڕیار یان قەرزدار بنووسە');
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

    Customer? customer = _matchedCustomer;
    final String cName = _customerNameController.text.trim();
    final String cPhone = _customerPhoneController.text.trim();

    if (cName.isNotEmpty || cPhone.isNotEmpty) {
      customer = await customerController.findOrCreate(
        name: cName,
        phone: cPhone,
      );
    }

    if (customer != null && _usePoints && _pointsToRedeem > 0) {
      await customerController.redeemPoints(
        customerId: customer.id,
        pointsToUse: _pointsToRedeem,
        amountPerPoint: settings.settings.amountPerPoint,
      );
    }

    int earnedPoints = 0;
    if (customer != null && settings.settings.pointsEnabled) {
      earnedPoints = await customerController.earnPoints(
        customerId: customer.id,
        spentAmount: payable,
        pointsPerAmount: settings.settings.pointsPerAmount,
      );
    }

    final Sale sale = await sales.checkout(
      items: cart.items,
      cashier: cashier,
      inventory: inventory,
      discount: cart.safeDiscount,
      taxPercent: cart.taxPercent,
      paymentMethod: _method,
      paidAmount: paid,
      customerName: customer?.name ?? cName,
      customerPhone: customer?.phone ?? cPhone,
      note: _noteController.text.trim(),
      pointsUsed: _usePoints ? _pointsToRedeem : 0,
      pointsDiscount: _pointsDiscount,
      pointsEarned: earnedPoints,
    );

    cart.resetAfterSale();
    if (!mounted) return;
    Navigator.of(context).pop(sale);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();
    final double change = _paid - _payableTotal;
    final int potentialPoints = _calculatePotentialEarnedPoints();

    return AlertDialog(
      title: const Text(AppStrings.checkoutTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // بڕی گشتی و داشکاندن بە پۆینت
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          AppStrings.total,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          settings.money(_cartTotal),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: _pointsDiscount > 0
                                ? TextDecoration.lineThrough
                                : null,
                            color: _pointsDiscount > 0
                                ? theme.textTheme.bodySmall?.color
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (_pointsDiscount > 0) ...<Widget>[
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'داشکاندن بە پۆینت ($_pointsToRedeem پۆینت)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '- ${settings.money(_pointsDiscount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      children: <Widget>[
                        Text(
                          'کۆی شایستەی پارەدان',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          settings.money(_payableTotal),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // شێوازی پارەدان
              Text(AppStrings.paymentMethod, style: theme.textTheme.labelLarge),
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
                      if (method == PaymentMethod.credit) {
                        _paidController.text = '0';
                      } else {
                        _paidController.text = Formatters.number(_payableTotal);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // بەشی کڕیار و پۆینتی وەفاداری
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _matchedCustomer != null
                        ? Colors.amber.shade400
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.stars, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'کڕیار و پۆینتی وەفاداری (Loyalty)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'هەڵبژاردنی کڕیار لە لیست',
                          icon: const Icon(Icons.contacts_outlined, size: 20),
                          onPressed: _pickCustomerDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'ژمارەی مۆبایلی کڕیار',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        suffixIcon: _customerPhoneController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _customerPhoneController.clear();
                                  _onCustomerPhoneOrNameChanged();
                                },
                              )
                            : null,
                        isDense: true,
                      ),
                      onChanged: (_) => _onCustomerPhoneOrNameChanged(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: _method == PaymentMethod.credit
                            ? AppStrings.customerName
                            : '${AppStrings.customerName} (${AppStrings.optional})',
                        prefixIcon: const Icon(Icons.person_outline),
                        isDense: true,
                      ),
                      onChanged: (_) => _onCustomerPhoneOrNameChanged(),
                    ),

                    if (_matchedCustomer != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${_matchedCustomer!.name}: خاوەنی ${_matchedCustomer!.points} پۆینتە '
                                    '(${settings.money(_matchedCustomer!.points * settings.settings.amountPerPoint)})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (settings.settings.pointsEnabled &&
                                _matchedCustomer!.points > 0) ...<Widget>[
                              const Divider(height: 12),
                              Row(
                                children: <Widget>[
                                  Text(
                                    'بەکارهێنانی پۆینت بۆ داشکاندن:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _usePoints,
                                    onChanged: _toggleUsePoints,
                                  ),
                                ],
                              ),
                              if (_usePoints) ...<Widget>[
                                const SizedBox(height: 4),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextField(
                                        controller: _pointsController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'ژمارەی پۆینت بۆ داشکاندن',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (String val) {
                                          final int pts =
                                              int.tryParse(val) ?? 0;
                                          setState(() {
                                            _pointsToRedeem = pts;
                                            if (_matchedCustomer != null) {
                                              _clampPoints(_matchedCustomer!);
                                            }
                                            _syncPaidWithPayable();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ActionChip(
                                      label: const Text('هەمووی'),
                                      onPressed: () {
                                        if (_matchedCustomer != null) {
                                          _toggleUsePoints(true);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],

                    if (settings.settings.pointsEnabled &&
                        potentialPoints > 0) ...<Widget>[
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.card_giftcard,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'پۆینتی بەدەستهاتوو دوای ئەم کڕینە: +$potentialPoints پۆینت',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (_method == PaymentMethod.credit) ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(
                    labelText: AppStrings.initialPayment,
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ActionChip(
                      label: const Text('بێ پێشەکی (٠)'),
                      onPressed: () =>
                          setState(() => _paidController.text = '0'),
                    ),
                    if (_payableTotal > 0)
                      ActionChip(
                        label: Text(
                          'نیوەی (${Formatters.number((_payableTotal / 2).roundToDouble())})',
                        ),
                        onPressed: () => setState(
                          () => _paidController.text = Formatters.number(
                            (_payableTotal / 2).roundToDouble(),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.remainingDebt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        settings.money(_remainingDebt),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...<Widget>[
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
                      onPressed: () => setState(
                        () => _paidController.text = Formatters.number(
                          _payableTotal,
                        ),
                      ),
                    ),
                    ..._roundAmounts(_payableTotal).map(
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
