import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../state/inventory_controller.dart';
import '../widgets/app_widgets.dart';

/// کردنەوەی فۆرمی کاڵا (زیادکردن یان دەستکاری).
/// English: opens the create/edit product dialog.
Future<void> openProductForm(BuildContext context, {Product? product}) async {
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) =>
        _ProductFormDialog(product: product),
  );
  if (saved == true && context.mounted) {
    AppDialogs.showMessage(context, AppStrings.productSaved);
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _costController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;

  late String _categoryId;
  late ProductUnit _unit;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final Product? product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _costController = TextEditingController(
      text: product == null ? '' : Formatters.number(product.costPrice),
    );
    _priceController = TextEditingController(
      text: product == null ? '' : Formatters.number(product.salePrice),
    );
    _stockController = TextEditingController(
      text: product == null ? '' : Formatters.quantity(product.stock),
    );
    _thresholdController = TextEditingController(
      text: product == null
          ? '5'
          : Formatters.quantity(product.lowStockThreshold),
    );
    _categoryId = product?.categoryId ?? '';
    _unit = product?.unit ?? ProductUnit.piece;
    _isActive = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  double _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final Product product = Product(
      id: widget.product?.id ?? 'p-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      categoryId: _categoryId,
      unit: _unit,
      costPrice: _parse(_costController.text),
      salePrice: _parse(_priceController.text),
      stock: _parse(_stockController.text),
      lowStockThreshold: _parse(_thresholdController.text),
      isActive: _isActive,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    await context.read<InventoryController>().upsertProduct(product);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.required;
    if (double.tryParse(value.trim().replaceAll(',', '')) == null) {
      return AppStrings.invalidNumber;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<Category> categories = context
        .watch<InventoryController>()
        .categoriesWithUncategorized;

    return AlertDialog(
      title: Text(
        widget.product == null ? AppStrings.addProduct : AppStrings.editProduct,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.productName,
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.barcode} (${AppStrings.optional})',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.category,
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map(
                        (Category category) => DropdownMenuItem<String>(
                          value: category.id == Category.uncategorizedId
                              ? ''
                              : category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) =>
                      setState(() => _categoryId = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductUnit>(
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: AppStrings.unit,
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  items: ProductUnit.values
                      .map(
                        (ProductUnit unit) => DropdownMenuItem<ProductUnit>(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (ProductUnit? value) =>
                      setState(() => _unit = value ?? ProductUnit.piece),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: AppStrings.costPrice,
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: AppStrings.salePrice,
                        ),
                        validator: (String? value) {
                          final String? base = _numberValidator(value);
                          if (base != null) return base;
                          final double price = _parse(value ?? '');
                          final double cost = _parse(_costController.text);
                          if (price < cost) return AppStrings.invalidPrice;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: widget.product == null
                              ? AppStrings.initialStock
                              : AppStrings.stock,
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: AppStrings.lowStockThreshold,
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (bool value) => setState(() => _isActive = value),
                  title: const Text(AppStrings.active),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
