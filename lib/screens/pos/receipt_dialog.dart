import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../models/sale.dart';
import '../../models/store_settings.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/receipt_view.dart';

/// پیشاندانی وەسڵی فرۆشتن دوای پارەدان (لەگەڵ کۆپیکردن).
/// English: shows the receipt right after a sale and lets the cashier copy it
/// (or print it with the browser/OS print dialog).
Future<void> showReceiptDialog(BuildContext context, Sale sale) async {
  final StoreSettings settings = context.read<SettingsController>().settings;

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      final ThemeData theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text(AppStrings.receipt),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ReceiptView(sale: sale, settings: settings),
                const SizedBox(height: 12),
                Text(
                  AppStrings.printHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: buildReceiptText(sale: sale, settings: settings),
                ),
              );
              if (!dialogContext.mounted) return;
              AppDialogs.showMessage(dialogContext, AppStrings.receiptCopied);
            },
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text(AppStrings.copyReceipt),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      );
    },
  );
}
