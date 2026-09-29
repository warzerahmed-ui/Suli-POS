import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/app_user.dart';
import '../models/sale.dart';
import '../state/auth_controller.dart';
import '../state/inventory_controller.dart';
import '../state/sales_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/receipt_view.dart';

/// وردەکاری پسووڵەیەک (وەسڵ + قازانج + هەڵوەشاندنەوە).
/// English: one invoice: the receipt, its numbers and the void action.
class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final String saleId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SalesController sales = context.watch<SalesController>();
    final InventoryController inventory = context.watch<InventoryController>();
    final SettingsController settings = context.watch<SettingsController>();
    final bool isAdmin = context.watch<AuthController>().isAdmin;
    final Sale? sale = sales.saleById(saleId);

    if (sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.invoice)),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: AppStrings.noData,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sale.id),
        actions: <Widget>[
          IconButton(
            tooltip: AppStrings.copyReceipt,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: buildReceiptText(
                    sale: sale,
                    settings: settings.settings,
                  ),
                ),
              );
              if (!context.mounted) return;
              AppDialogs.showMessage(context, AppStrings.receiptCopied);
            },
          ),
          if (isAdmin && !sale.isVoided)
            IconButton(
              tooltip: AppStrings.voidSale,
              icon: Icon(Icons.undo, color: theme.colorScheme.error),
              onPressed: () => _voidSale(context, sale),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (sale.isVoided)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${AppStrings.voided} — ${AppStrings.voidedBy} '
                          '${sale.voidedBy ?? ''}'
                          '${sale.voidedAt == null ? '' : ' (${Formatters.dateTime(sale.voidedAt!)})'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SectionCard(
            title: AppStrings.details,
            child: Column(
              children: <Widget>[
                _row(context, AppStrings.cashier, sale.cashierName),
                _row(
                  context,
                  AppStrings.date,
                  Formatters.dateTime(sale.createdAt),
                ),
                _row(context, AppStrings.lineItems, '${sale.lineCount}'),
                _row(
                  context,
                  AppStrings.quantity,
                  Formatters.quantity(sale.itemQuantity),
                ),
                _row(
                  context,
                  AppStrings.paymentMethod,
                  sale.paymentMethod.label,
                ),
                if (isAdmin) ...<Widget>[
                  const Divider(height: 20),
                  _row(
                    context,
                    AppStrings.totalCost,
                    settings.money(sale.totalCost),
                  ),
                  _row(
                    context,
                    AppStrings.profit,
                    settings.money(sale.profit),
                    valueColor: StatusColors.success(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: AppStrings.receipt,
            child: ReceiptView(sale: sale, settings: settings.settings),
          ),
          const SizedBox(height: 16),
          if (isAdmin && !sale.isVoided)
            OutlinedButton.icon(
              onPressed: () => _voidSale(context, sale),
              icon: Icon(Icons.undo, color: theme.colorScheme.error),
              label: Text(
                AppStrings.voidSale,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// هەڵوەشاندنەوەی پسووڵە — کاڵاکان دەگەڕێنەوە کۆگا.
  Future<void> _voidSale(BuildContext context, Sale sale) async {
    final bool confirmed = await AppDialogs.confirm(
      context,
      message: AppStrings.voidSaleConfirm,
      confirmLabel: AppStrings.voidSale,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    final AppUser? user = context.read<AuthController>().currentUser;
    if (user == null) return;
    await context.read<SalesController>().voidSale(
          sale.id,
          user: user,
          inventory: context.read<InventoryController>(),
        );
    if (!context.mounted) return;
    AppDialogs.showMessage(context, AppStrings.saleVoided);
  }
}
