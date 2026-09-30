import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../models/category.dart';
import '../state/inventory_controller.dart';
import '../widgets/app_widgets.dart';

/// شاشەی پۆلەکان: زیادکردن، دەستکاری و سڕینەوە.
/// English: manage the product categories (name, icon, colour).
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InventoryController inventory = context.watch<InventoryController>();
    final List<Category> categories = inventory.categories;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.categories)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCategoryForm(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addCategory),
      ),
      body: categories.isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              title: AppStrings.noData,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final Category category = categories[index];
                final int productCount = inventory.productCountInCategory(
                  category.id,
                );
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
                    title: Text(
                      category.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('${AppStrings.productCount}: $productCount'),
                    trailing: PopupMenuButton<String>(
                      tooltip: AppStrings.actions,
                      onSelected: (String value) async {
                        if (value == 'edit') {
                          await openCategoryForm(context, category: category);
                          return;
                        }
                        final bool confirmed = await AppDialogs.confirm(
                          context,
                          message: AppStrings.deleteCategoryConfirm,
                          confirmLabel: AppStrings.delete,
                          danger: true,
                        );
                        if (!confirmed) return;
                        await inventory.deleteCategory(category.id);
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(AppStrings.edit),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                AppStrings.delete,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// ڕەنگە پێشنیارکراوەکانی پۆل.
const List<int> _categoryColors = <int>[
  0xFF14795F,
  0xFF2E7D32,
  0xFF558B2F,
  0xFF0288D1,
  0xFF1565C0,
  0xFF6A1B9A,
  0xFFAD1457,
  0xFFEF6C00,
  0xFF795548,
  0xFF455A64,
];

/// کردنەوەی فۆرمی پۆل (زیادکردن یان دەستکاری).
Future<void> openCategoryForm(
  BuildContext context, {
  Category? category,
}) async {
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) =>
        _CategoryFormDialog(category: category),
  );
  if (saved == true && context.mounted) {
    AppDialogs.showMessage(context, AppStrings.saved);
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});

  final Category? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final TextEditingController _nameController = TextEditingController();

  late String _iconKey;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
    _iconKey = widget.category?.iconKey ?? CategoryIcons.keys.first;
    _colorValue = widget.category?.colorValue ?? _categoryColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    final Category category = Category(
      id: widget.category?.id ?? 'cat-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      iconKey: _iconKey,
      colorValue: _colorValue,
    );
    await context.read<InventoryController>().upsertCategory(category);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color selectedColor = Color(_colorValue);

    return AlertDialog(
      title: Text(
        widget.category == null
            ? AppStrings.addCategory
            : AppStrings.editCategory,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.categoryName,
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.icon, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryIcons.keys.map((String key) {
                  final bool selected = key == _iconKey;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _iconKey = key),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? selectedColor.withValues(alpha: 0.18)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? selectedColor
                              : theme.colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        CategoryIcons.resolve(key),
                        size: 18,
                        color: selected
                            ? selectedColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.color, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryColors.map((int value) {
                  final Color color = Color(value);
                  final bool selected = value == _colorValue;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _colorValue = value),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
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
