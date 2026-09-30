import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../state/inventory_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import 'categories_screen.dart';
import 'product_form_screen.dart';

/// شاشەی کاڵاکان: گەڕان، فلتەر، زیادکردن/دەستکاری/سڕینەوە و کۆگا.
/// English: the product catalogue screen.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = '';
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InventoryController inventory = context.watch<InventoryController>();
    final SettingsController settings = context.watch<SettingsController>();
    final List<Product> products = inventory.search(
      query: _query,
      categoryId: _categoryId,
      includeInactive: _showInactive,
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (String value) =>
                          setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: AppStrings.search,
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const CategoriesScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.category_outlined),
                    label: const Text(AppStrings.categories),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => openProductForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addProduct),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          FilterChip(
                            label: const Text(AppStrings.allCategories),
                            selected: _categoryId.isEmpty,
                            onSelected: (_) => setState(() => _categoryId = ''),
                          ),
                          const SizedBox(width: 8),
                          ...inventory.categories.map(
                            (Category category) => Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: FilterChip(
                                avatar: Icon(
                                  category.icon,
                                  size: 16,
                                  color: category.color,
                                ),
                                label: Text(
                                  '${category.name} '
                                  '(${inventory.productCountInCategory(category.id)})',
                                ),
                                selected: _categoryId == category.id,
                                onSelected: (_) => setState(
                                  () => _categoryId = _categoryId == category.id
                                      ? ''
                                      : category.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text(AppStrings.showInactive),
                    selected: _showInactive,
                    onSelected: (bool value) =>
                        setState(() => _showInactive = value),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              _summary(context, AppStrings.productCount, '${products.length}'),
              _summary(
                context,
                AppStrings.inventoryValue,
                settings.money(inventory.inventoryValue),
              ),
              _summary(
                context,
                AppStrings.lowStockItems,
                '${inventory.lowStockProducts.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: AppStrings.noData,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) =>
                      _ProductTile(product: products[index]),
                ),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context, String label, String value) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// کارتی کاڵایەک لە لیستەکە لەگەڵ کردارەکان.
class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InventoryController inventory = context.read<InventoryController>();
    final SettingsController settings = context.watch<SettingsController>();
    final Category category = inventory.categoryById(product.categoryId);

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, color: category.color),
        ),
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                product.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!product.isActive)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Chip(
                  label: const Text(AppStrings.inactive),
                  labelStyle: theme.textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: <Widget>[
              Text('${AppStrings.category}: ${category.name}'),
              Text(
                '${AppStrings.salePrice}: ${settings.money(product.salePrice)}',
              ),
              Text(
                '${AppStrings.costPrice}: ${settings.money(product.costPrice)}',
              ),
              Text(
                '${AppStrings.stock}: ${Formatters.quantity(product.stock)} '
                '${product.unit.shortLabel}',
                style: TextStyle(
                  color: product.needsReorder ? theme.colorScheme.error : null,
                  fontWeight: product.needsReorder ? FontWeight.w700 : null,
                ),
              ),
              if (product.barcode.isNotEmpty)
                Text('${AppStrings.barcode}: ${product.barcode}'),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: AppStrings.actions,
          onSelected: (String value) => _handle(context, value),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text(AppStrings.edit),
            ),
            const PopupMenuItem<String>(
              value: 'restock',
              child: Text(AppStrings.stock),
            ),
            PopupMenuItem<String>(
              value: 'toggle',
              child: Text(
                product.isActive ? AppStrings.inactive : AppStrings.active,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                AppStrings.delete,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(BuildContext context, String action) async {
    final InventoryController inventory = context.read<InventoryController>();
    switch (action) {
      case 'edit':
        await openProductForm(context, product: product);
      case 'restock':
        await openRestockDialog(context, product);
      case 'toggle':
        await inventory.upsertProduct(
          product.copyWith(isActive: !product.isActive),
        );
      case 'delete':
        final bool confirmed = await AppDialogs.confirm(
          context,
          message: AppStrings.deleteProductConfirm,
          confirmLabel: AppStrings.delete,
          danger: true,
        );
        if (!confirmed) return;
        await inventory.deleteProduct(product.id);
        if (!context.mounted) return;
        AppDialogs.showMessage(context, AppStrings.deleted);
    }
  }
}

/// زیادکردن بڕی نوێ بۆ کۆگای کاڵایەک (کڕینی نوێ).
Future<void> openRestockDialog(BuildContext context, Product product) async {
  final TextEditingController controller = TextEditingController();
  final double? amount = await showDialog<double>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text('${AppStrings.stock} — ${product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${AppStrings.remainingStock}: '
            '${Formatters.quantity(product.stock)} '
            '${product.unit.shortLabel}',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${AppStrings.add} (${product.unit.label})',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            dialogContext,
          ).pop(double.tryParse(controller.text.trim().replaceAll(',', ''))),
          child: const Text(AppStrings.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (amount == null || amount == 0 || !context.mounted) return;

  await context.read<InventoryController>().adjustStock(product.id, amount);
  if (!context.mounted) return;
  AppDialogs.showMessage(context, AppStrings.saved);
}
