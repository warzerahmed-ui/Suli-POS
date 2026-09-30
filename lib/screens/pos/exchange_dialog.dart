import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_user.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../state/auth_controller.dart';
import '../../state/inventory_controller.dart';
import '../../state/sales_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import 'receipt_dialog.dart';

/// مۆدێلی یارمەتیدەر بۆ دێڕی ئاڵوگۆڕ
class _ExchangeItemRow {
  _ExchangeItemRow({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  Product product;
  double quantity;
  double unitPrice;

  double get total => quantity * unitPrice;
}

/// پیشاندانی دیالۆگی فەرمی ئاڵوگۆڕی کاڵا و هەژمارکردنی ساقی و باقی
Future<void> showExchangeDialog(
  BuildContext context, {
  Sale? initialReturnedSale,
}) async {
  final Sale? result = await showDialog<Sale>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) =>
        _ExchangeDialog(initialReturnedSale: initialReturnedSale),
  );

  if (result != null && context.mounted) {
    AppDialogs.showMessage(context, AppStrings.exchangeCompleted);
    await showReceiptDialog(context, result);
  }
}

class _ExchangeDialog extends StatefulWidget {
  const _ExchangeDialog({this.initialReturnedSale});

  final Sale? initialReturnedSale;

  @override
  State<_ExchangeDialog> createState() => _ExchangeDialogState();
}

class _ExchangeDialogState extends State<_ExchangeDialog> {
  final List<_ExchangeItemRow> _returnedItems = <_ExchangeItemRow>[];
  final List<_ExchangeItemRow> _newItems = <_ExchangeItemRow>[];

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // ئەگەر لەسەر پسووڵەیەکی پێشوو کرابێتەوە، کاڵاکانی پێشوو دابنێ
    if (widget.initialReturnedSale != null) {
      final InventoryController inventory = context.read<InventoryController>();
      _customerNameController.text = widget.initialReturnedSale!.customerName;
      _customerPhoneController.text = widget.initialReturnedSale!.customerPhone;
      for (final SaleItem item in widget.initialReturnedSale!.items) {
        if (item.quantity > 0) {
          final Product? p = inventory.productById(item.productId);
          if (p != null) {
            _returnedItems.add(
              _ExchangeItemRow(
                product: p,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
              ),
            );
          }
        }
      }
    }
    _recalculatePaid();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _noteController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  double get _returnedTotal => _returnedItems.fold<double>(
        0,
        (double sum, _ExchangeItemRow item) => sum + item.total,
      );

  double get _newTotal => _newItems.fold<double>(
        0,
        (double sum, _ExchangeItemRow item) => sum + item.total,
      );

  /// ساقی و باقی: ئەگەر ئەرێنی بێت کڕیار دەبێت بیبات، ئەگەر نەرێنی بێت دەگەڕێتەوە بۆ کڕیار
  double get _balanceDue => _newTotal - _returnedTotal;

  void _recalculatePaid() {
    final double bal = _balanceDue;
    if (bal > 0) {
      _paidController.text = Formatters.number(bal);
    } else {
      _paidController.text = '0';
    }
  }

  void _addReturnedProduct(Product product) {
    setState(() {
      final int idx = _returnedItems
          .indexWhere((_ExchangeItemRow r) => r.product.id == product.id);
      if (idx >= 0) {
        _returnedItems[idx].quantity += 1;
      } else {
        _returnedItems.add(
          _ExchangeItemRow(
            product: product,
            quantity: 1,
            unitPrice: product.salePrice,
          ),
        );
      }
      _errorMessage = null;
      _recalculatePaid();
    });
  }

  void _addNewProduct(Product product) {
    setState(() {
      final int idx = _newItems
          .indexWhere((_ExchangeItemRow r) => r.product.id == product.id);
      if (idx >= 0) {
        _newItems[idx].quantity += 1;
      } else {
        _newItems.add(
          _ExchangeItemRow(
            product: product,
            quantity: 1,
            unitPrice: product.salePrice,
          ),
        );
      }
      _errorMessage = null;
      _recalculatePaid();
    });
  }

  Future<void> _submitExchange() async {
    if (_returnedItems.isEmpty && _newItems.isEmpty) {
      setState(() => _errorMessage = 'تکایە لانیکەم کاڵایەک بۆ ئاڵوگۆڕ دیاری بکە');
      return;
    }

    final AppUser? cashier = context.read<AuthController>().currentUser;
    if (cashier == null) return;

    final InventoryController inventory = context.read<InventoryController>();
    final SalesController sales = context.read<SalesController>();

    // پشکنینی بڕی کۆگا بۆ کاڵا نوێیەکان
    for (final _ExchangeItemRow item in _newItems) {
      final Product? latest = inventory.productById(item.product.id);
      if (latest != null && item.quantity > latest.stock) {
        setState(() {
          _errorMessage =
              'بڕی داواکراو بۆ «${item.product.name}» لە کۆگادا بەردەست نییە (${Formatters.quantity(latest.stock)})';
        });
        return;
      }
    }

    final double paid =
        double.tryParse(_paidController.text.trim().replaceAll(',', '')) ??
            (_balanceDue > 0 ? _balanceDue : 0);

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final List<SaleItem> returnedSaleItems = _returnedItems
          .map(
            (_ExchangeItemRow r) => SaleItem(
              productId: r.product.id,
              name: r.product.name,
              unit: r.product.unit,
              unitPrice: r.unitPrice,
              unitCost: r.product.costPrice,
              quantity: r.quantity,
            ),
          )
          .toList();

      final List<SaleItem> newSaleItems = _newItems
          .map(
            (_ExchangeItemRow r) => SaleItem(
              productId: r.product.id,
              name: r.product.name,
              unit: r.product.unit,
              unitPrice: r.unitPrice,
              unitCost: r.product.costPrice,
              quantity: r.quantity,
            ),
          )
          .toList();

      final String customNote = _noteController.text.trim();
      final String note = customNote.isNotEmpty
          ? customNote
          : '${AppStrings.exchangeNoteDefault} • ساقی و باقی: ${Formatters.money(_balanceDue)}';

      final Sale createdSale = await sales.processExchange(
        returnedItems: returnedSaleItems,
        newItems: newSaleItems,
        cashier: cashier,
        inventory: inventory,
        paymentMethod: _paymentMethod,
        paidAmount: paid,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        note: note,
      );

      if (mounted) {
        Navigator.of(context).pop(createdSale);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'هەڵەیەک ڕوویدا لە کاتی ئاڵوگۆڕ: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();
    final InventoryController inventory = context.watch<InventoryController>();

    final double width = MediaQuery.sizeOf(context).width;
    final bool wide = width >= 900;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 780),
        child: Column(
          children: <Widget>[
            // ── هێدەری سەرەوە ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppStrings.exchange,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          AppStrings.exchangeSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: theme.colorScheme.errorContainer,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),

            // ── بەشی ناوەوەی ئاڵوگۆڕ ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // بەشی ١: کاڵای گەڕاوە
                          Expanded(
                            child: _buildItemPanel(
                              context: context,
                              inventory: inventory,
                              settings: settings,
                              title: AppStrings.returnedItem,
                              subtitle: 'دەگەڕێتەوە بۆ کۆگا (+ زیاد دەبێت)',
                              isReturn: true,
                              items: _returnedItems,
                              accentColor: const Color(0xFFDC2626),
                              onAddProduct: _addReturnedProduct,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // بەشی ٢: کاڵای نوێ
                          Expanded(
                            child: _buildItemPanel(
                              context: context,
                              inventory: inventory,
                              settings: settings,
                              title: AppStrings.newItem,
                              subtitle: 'دەردەچێت لە کۆگا (- کەم دەبێت)',
                              isReturn: false,
                              items: _newItems,
                              accentColor: const Color(0xFF10B981),
                              onAddProduct: _addNewProduct,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: <Widget>[
                          _buildItemPanel(
                            context: context,
                            inventory: inventory,
                            settings: settings,
                            title: AppStrings.returnedItem,
                            subtitle: 'دەگەڕێتەوە بۆ کۆگا (+ زیاد دەبێت)',
                            isReturn: true,
                            items: _returnedItems,
                            accentColor: const Color(0xFFDC2626),
                            onAddProduct: _addReturnedProduct,
                          ),
                          const SizedBox(height: 16),
                          _buildItemPanel(
                            context: context,
                            inventory: inventory,
                            settings: settings,
                            title: AppStrings.newItem,
                            subtitle: 'دەردەچێت لە کۆگا (- کەم دەبێت)',
                            isReturn: false,
                            items: _newItems,
                            accentColor: const Color(0xFF10B981),
                            onAddProduct: _addNewProduct,
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // ── هەژمارکردنی ساقی و باقی (Balance / Settlement) ──────
                    _buildBalanceCard(context, settings),

                    const SizedBox(height: 16),

                    // ── زانیاری کڕیار و تێبینی ──────────────────────────────
                    _buildCustomerInputs(context),
                  ],
                ),
              ),
            ),

            // ── دوگمەکانی تەواوکردن ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: <Widget>[
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.cancel),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _submitting ? null : _submitExchange,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _submitting ? 'پاشەکەوت دەکرێت...' : AppStrings.completeExchange,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بەشێک بۆ لیستکردن و زیادکردنی کاڵا (یان بۆ گەڕاوە یان بۆ نوێ)
  Widget _buildItemPanel({
    required BuildContext context,
    required InventoryController inventory,
    required SettingsController settings,
    required String title,
    required String subtitle,
    required bool isReturn,
    required List<_ExchangeItemRow> items,
    required Color accentColor,
    required void Function(Product) onAddProduct,
  }) {
    final ThemeData theme = Theme.of(context);
    final double total = items.fold<double>(0, (double s, _ExchangeItemRow i) => s + i.total);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  child: Icon(
                    isReturn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: accentColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _ProductPickerButton(
                  inventory: inventory,
                  isReturn: isReturn,
                  onSelected: onAddProduct,
                ),
              ],
            ),
            const Divider(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        isReturn
                            ? Icons.assignment_return_outlined
                            : Icons.add_shopping_cart_outlined,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isReturn
                            ? 'هیچ کاڵایەکی گەڕاوە زیاد نەکراوە'
                            : 'هیچ کاڵایەکی نوێ زیاد نەکراوە',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final _ExchangeItemRow row = items[index];
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              row.product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${settings.money(row.unitPrice)} • کۆگا: ${Formatters.quantity(row.product.stock)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // کۆنترۆڵی بڕ
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        onPressed: () {
                          setState(() {
                            if (row.quantity > 1) {
                              row.quantity -= 1;
                            } else {
                              items.removeAt(index);
                            }
                            _recalculatePaid();
                          });
                        },
                      ),
                      Text(
                        Formatters.quantity(row.quantity),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        onPressed: () {
                          setState(() {
                            row.quantity += 1;
                            _recalculatePaid();
                          });
                        },
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(
                          settings.money(row.total),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            items.removeAt(index);
                            _recalculatePaid();
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            const Divider(height: 16),
            Row(
              children: <Widget>[
                Text(
                  'کۆی ئەم بەشە:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  settings.money(total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// کارتی زیرەکی ساقی و باقی (Balance / Settlement)
  Widget _buildBalanceCard(BuildContext context, SettingsController settings) {
    final ThemeData theme = Theme.of(context);
    final double balance = _balanceDue;

    final bool customerOwes = balance > 0;
    final bool storeRefunds = balance < 0;

    final Color cardColor = customerOwes
        ? const Color(0xFF10B981)
        : (storeRefunds ? const Color(0xFFF59E0B) : const Color(0xFF0284C7));

    final IconData icon = customerOwes
        ? Icons.call_made_rounded
        : (storeRefunds ? Icons.call_received_rounded : Icons.check_circle_rounded);

    final String statusText = customerOwes
        ? 'ساقی و باقی: کڕیار دەبێت جیاوازی بدات (+)'
        : (storeRefunds
            ? 'ساقی و باقی: ئەم بڕە دەگەڕێتەوە بۆ کڕیار لە قاسەی دەست (-)'
            : 'ساقی و باقی: یەکسانە و هیچ بڕە پارەیەک نادرێت');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: cardColor,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.balanceSettlement,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cardColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                settings.money(balance.abs()),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cardColor,
                ),
              ),
            ],
          ),
          if (customerOwes) ...<Widget>[
            const Divider(height: 20),
            Row(
              children: <Widget>[
                const Text('شێوازی پارەدان: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('نەقد (Cash)'),
                  selected: _paymentMethod == PaymentMethod.cash,
                  onSelected: (bool sel) {
                    if (sel) setState(() => _paymentMethod = PaymentMethod.cash);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('کارت (Card)'),
                  selected: _paymentMethod == PaymentMethod.card,
                  onSelected: (bool sel) {
                    if (sel) setState(() => _paymentMethod = PaymentMethod.card);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('قەرز (Credit)'),
                  selected: _paymentMethod == PaymentMethod.credit,
                  onSelected: (bool sel) {
                    if (sel) setState(() => _paymentMethod = PaymentMethod.credit);
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _paidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'بڕی پارەی دراو',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// زانیاری کڕیار و تێبینی
  Widget _buildCustomerInputs(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'ناوی کڕیار (ئارەزوومەندانە)',
              prefixIcon: Icon(Icons.person_outline),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'ژمارەی تەلەفۆن (ئارەزوومەندانە)',
              prefixIcon: Icon(Icons.phone_outlined),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'تێبینی ئاڵوگۆڕ',
              prefixIcon: Icon(Icons.note_alt_outlined),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// دوگمەی دیاریکردنی کاڵا لە لیستی کاڵاکان
class _ProductPickerButton extends StatelessWidget {
  const _ProductPickerButton({
    required this.inventory,
    required this.isReturn,
    required this.onSelected,
  });

  final InventoryController inventory;
  final bool isReturn;
  final void Function(Product) onSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
      icon: const Icon(Icons.add, size: 16),
      label: Text(isReturn ? 'دیاریکردنی گەڕاوە' : 'دیاریکردنی نوێ'),
      onPressed: () async {
        final Product? picked = await showDialog<Product>(
          context: context,
          builder: (BuildContext ctx) => _ProductSearchDialog(inventory: inventory),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
    );
  }
}

/// دیالۆگی خێرای گەڕان و هەڵبژاردنی کاڵا
class _ProductSearchDialog extends StatefulWidget {
  const _ProductSearchDialog({required this.inventory});

  final InventoryController inventory;

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> list = widget.inventory.search(query: _query);
    final SettingsController settings = context.watch<SettingsController>();

    return AlertDialog(
      title: const Text('دیاریکردنی کاڵا بۆ ئاڵوگۆڕ'),
      content: SizedBox(
        width: 480,
        height: 400,
        child: Column(
          children: <Widget>[
            TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'گەڕان بە ناو یان بارکۆد...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (String v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('هیچ کاڵایەک نەدۆزرایەوە'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (BuildContext ctx, int i) {
                        final Product p = list[i];
                        return ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'بارکۆد: ${p.barcode.isEmpty ? "نییە" : p.barcode} • کۆگا: ${Formatters.quantity(p.stock)}',
                          ),
                          trailing: Text(
                            settings.money(p.salePrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () => Navigator.of(ctx).pop(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }
}
