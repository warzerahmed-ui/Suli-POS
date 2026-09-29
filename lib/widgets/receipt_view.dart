import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';

/// وەسڵی فرۆشتن وەک دەقی سادە (بۆ کۆپیکردن یان چاپکردن).
/// English: the receipt as plain text — used for copy-to-clipboard / printing.
String buildReceiptText({
  required Sale sale,
  required StoreSettings settings,
}) {
  final StringBuffer buffer = StringBuffer();
  final String line = '-' * 32;

  buffer.writeln(settings.storeName);
  if (settings.address.isNotEmpty) buffer.writeln(settings.address);
  if (settings.phone.isNotEmpty) {
    buffer.writeln('${AppStrings.phone}: ${settings.phone}');
  }
  buffer.writeln(line);
  buffer.writeln('${AppStrings.invoiceNumber}: ${sale.id}');
  buffer.writeln('${AppStrings.date}: ${Formatters.dateTime(sale.createdAt)}');
  buffer.writeln('${AppStrings.cashier}: ${sale.cashierName}');
  buffer.writeln(line);

  for (int index = 0; index < sale.items.length; index++) {
    final SaleItem item = sale.items[index];
    buffer.writeln('${index + 1}. ${item.name}');
    buffer.writeln(
      '   ${Formatters.quantity(item.quantity)} ${item.unit.shortLabel} × '
      '${receiptMoney(settings, item.unitPrice)} = '
      '${receiptMoney(settings, item.total)}',
    );
  }

  buffer.writeln(line);
  buffer.writeln('${AppStrings.subtotal}: ${receiptMoney(settings, sale.subtotal)}');
  if (sale.safeDiscount > 0) {
    buffer.writeln(
      '${AppStrings.discount}: ${receiptMoney(settings, sale.safeDiscount)}',
    );
  }
  if (sale.taxPercent > 0) {
    buffer.writeln(
      '${AppStrings.tax} (${Formatters.percent(sale.taxPercent)}): '
      '${receiptMoney(settings, sale.taxAmount)}',
    );
  }
  buffer.writeln('${AppStrings.total}: ${receiptMoney(settings, sale.total)}');
  buffer.writeln(
    '${AppStrings.paidAmount}: ${receiptMoney(settings, sale.paidAmount)}',
  );
  buffer.writeln('${AppStrings.change}: ${receiptMoney(settings, sale.change)}');
  buffer.writeln('${AppStrings.paymentMethod}: ${sale.paymentMethod.label}');
  if (sale.note.trim().isNotEmpty) {
    buffer.writeln('${AppStrings.note}: ${sale.note.trim()}');
  }
  buffer.writeln(line);
  if (sale.isVoided) buffer.writeln('*** ${AppStrings.voided} ***');
  if (settings.receiptFooter.trim().isNotEmpty) {
    buffer.writeln(settings.receiptFooter.trim());
  }
  buffer.writeln(AppStrings.thanksMessage);
  return buffer.toString();
}

/// شێوەکردنی بڕی پارە بەپێی ڕێکخستنەکانی فرۆشگا.
String receiptMoney(StoreSettings settings, num value) => Formatters.money(
      value,
      symbol: settings.currencySymbol,
      decimals: settings.currencyDecimals,
    );

/// وەسڵی فرۆشتن وەک ڕووکار (بۆ پیشاندان لە دیالۆگ یان لاپەڕە).
/// English: printable-looking receipt widget.
class ReceiptView extends StatelessWidget {
  const ReceiptView({
    super.key,
    required this.sale,
    required this.settings,
  });

  final Sale sale;
  final StoreSettings settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle metaStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              Text(
                settings.storeName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (settings.address.isNotEmpty)
                Text(settings.address, style: metaStyle),
              if (settings.phone.isNotEmpty)
                Text('${AppStrings.phone}: ${settings.phone}',
                    style: metaStyle),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        _metaRow(context, AppStrings.invoiceNumber, sale.id),
        _metaRow(context, AppStrings.date, Formatters.dateTime(sale.createdAt)),
        _metaRow(context, AppStrings.cashier, sale.cashierName),
        _metaRow(context, AppStrings.paymentMethod, sale.paymentMethod.label),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ...sale.items.map(
          (SaleItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${Formatters.quantity(item.quantity)} '
                        '${item.unit.shortLabel} × '
                        '${receiptMoney(settings, item.unitPrice)}',
                        style: metaStyle,
                      ),
                    ),
                    Text(
                      receiptMoney(settings, item.total),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _totalRow(context, AppStrings.subtotal, sale.subtotal),
        if (sale.safeDiscount > 0)
          _totalRow(context, AppStrings.discount, -sale.safeDiscount),
        if (sale.taxPercent > 0)
          _totalRow(
            context,
            '${AppStrings.tax} (${Formatters.percent(sale.taxPercent)})',
            sale.taxAmount,
          ),
        const SizedBox(height: 4),
        _totalRow(context, AppStrings.total, sale.total, bold: true),
        _totalRow(context, AppStrings.paidAmount, sale.paidAmount),
        _totalRow(context, AppStrings.change, sale.change),
        if (sale.note.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${AppStrings.note}: ${sale.note.trim()}',
              style: metaStyle,
            ),
          ),
        if (sale.isVoided)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '*** ${AppStrings.voided} ***',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        if (settings.receiptFooter.trim().isNotEmpty)
          Center(
            child: Text(
              settings.receiptFooter.trim(),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        Center(child: Text(AppStrings.thanksMessage, style: metaStyle)),
      ],
    );
  }

  Widget _metaRow(BuildContext context, String label, String value) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    double value, {
    bool bold = false,
  }) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = bold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(receiptMoney(settings, value), style: style),
        ],
      ),
    );
  }
}
