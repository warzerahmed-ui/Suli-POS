import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../models/cart_item.dart';
import '../../models/held_cart.dart';
import '../../state/cart_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import 'checkout_dialog.dart';

/// پانێلی سەبەتە: لیستی کاڵاکان، داشکاندن، کۆکردنەوە و پارەدان.
/// English: the cart side panel used by the POS screen.
class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CartController cart = context.watch<CartController>();
    final SettingsController settings = context.watch<SettingsController>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.shopping_cart_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.cart,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${cart.lineCount} ${AppStrings.lineItems} • '
                      '${Formatters.quantity(cart.itemQuantity)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (cart.heldCarts.isNotEmpty)
                IconButton(
                  tooltip: AppStrings.heldCarts,
                  onPressed: () => showHeldCartsSheet(context),
                  icon: Badge(
                    label: Text('${cart.heldCarts.length}'),
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                ),
              IconButton(
                tooltip: AppStrings.holdCart,
                onPressed: cart.isEmpty ? null : () => holdCurrentCart(context),
                icon: const Icon(Icons.pause_circle_outline),
              ),
              IconButton(
                tooltip: AppStrings.clearCart,
                onPressed: cart.isEmpty ? null : () => clearCart(context),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: AppStrings.emptyCart,
                  message: AppStrings.emptyCartHint,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: cart.items.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) =>
                      _CartRow(item: cart.items[index]),
                ),
        ),
        const Divider(height: 1),
        _TotalsArea(cart: cart, settings: settings),
      ],
    );
  }
}

/// دێرێکی کاڵا لە سەبەتە.
class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CartController cart = context.read<CartController>();

    void change(String? Function() action) {
      final String? error = action();
      if (error != null) AppDialogs.showMessage(context, error, isError: true);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.delete,
                visualDensity: VisualDensity.compact,
                onPressed: () => cart.removeItem(item.productId),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              _QtyButton(
                icon: Icons.remove,
                onPressed: () =>
                    change(() => cart.decreaseQuantity(item.productId)),
              ),
              Container(
                width: 56,
                alignment: Alignment.center,
                child: Text(
                  '${Formatters.quantity(item.quantity)} '
                  '${item.unit.shortLabel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onPressed: () =>
                    change(() => cart.increaseQuantity(item.productId)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${Formatters.quantity(item.quantity)} × '
                    '${Formatters.number(item.unitPrice)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    Formatters.number(item.lineTotal),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.exceedsStock)
            Text(
              AppStrings.insufficientStock,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

/// دوگمەی زیادکردن/کەمکردنەوەی بڕ.
class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }
}

/// کۆی کاڵاکان، داشکاندن، باج و دوگمەی پارەدان.
class _TotalsArea extends StatelessWidget {
  const _TotalsArea({required this.cart, required this.settings});

  final CartController cart;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          _summaryRow(context, AppStrings.subtotal, settings.money(cart.subtotal)),
          InkWell(
            onTap: () => editDiscount(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Icon(Icons.percent, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(AppStrings.discount, style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    settings.money(cart.safeDiscount),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (cart.taxPercent > 0)
            _summaryRow(
              context,
              '${AppStrings.tax} (${Formatters.percent(cart.taxPercent)})',
              settings.money(cart.taxAmount),
            ),
          const Divider(height: 16),
          Row(
            children: <Widget>[
              Text(
                AppStrings.total,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                settings.money(cart.total),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (cart.hasStockIssue)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.insufficientStock,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  cart.isEmpty ? null : () => showCheckoutDialog(context),
              icon: const Icon(Icons.point_of_sale),
              label: const Text(AppStrings.checkout),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// دەستکاریکردنی بڕی داشکاندن.
Future<void> editDiscount(BuildContext context) async {
  final CartController cart = context.read<CartController>();
  final TextEditingController controller = TextEditingController(
    text: cart.discount <= 0 ? '' : Formatters.number(cart.discount),
  );
  final double? value = await showDialog<double>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text(AppStrings.discount),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: AppStrings.amount),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(
            double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0,
          ),
          child: const Text(AppStrings.apply),
        ),
      ],
    ),
  );
  controller.dispose();
  if (value != null) cart.setDiscount(value);
}

/// پاککردنەوەی سەبەتە بە دڵنیاکردنەوە.
Future<void> clearCart(BuildContext context) async {
  final bool confirmed = await AppDialogs.confirm(
    context,
    message: AppStrings.clearCartConfirm,
    confirmLabel: AppStrings.clearCart,
    danger: true,
  );
  if (!confirmed || !context.mounted) return;
  context.read<CartController>().clear();
}

/// هەڵواسینی سەبەتە بۆ کڕیارێکی دیکە.
Future<void> holdCurrentCart(BuildContext context) async {
  final TextEditingController controller = TextEditingController();
  final String? label = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text(AppStrings.holdCart),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: AppStrings.note,
          hintText: 'ناوی کڕیار یان تێبینی',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text(AppStrings.confirm),
        ),
      ],
    ),
  );
  controller.dispose();
  if (label == null || !context.mounted) return;

  final CartController cart = context.read<CartController>();
  await cart.holdCart(label: label);
  if (!context.mounted) return;
  AppDialogs.showMessage(context, AppStrings.cartHeld);
}

/// لیستی سەبەتە هەڵواسراوەکان (گەڕاندنەوە یان سڕینەوە).
Future<void> showHeldCartsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) => Consumer<CartController>(
      builder: (BuildContext context, CartController cart, Widget? child) {
        final ThemeData theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                AppStrings.heldCarts,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (cart.heldCarts.isEmpty)
                const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: AppStrings.noData,
                )
              else
                ...cart.heldCarts.map(
                  (HeldCart held) => ListTile(
                    leading: const Icon(Icons.pause_circle_outline),
                    title: Text(held.label),
                    subtitle: Text(
                      '${Formatters.dateTime(held.createdAt)} • '
                      '${Formatters.quantity(held.itemQuantity)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            cart.resumeHeldCart(held.id);
                          },
                          child: const Text(AppStrings.resumeCart),
                        ),
                        IconButton(
                          tooltip: AppStrings.delete,
                          onPressed: () => cart.deleteHeldCart(held.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
