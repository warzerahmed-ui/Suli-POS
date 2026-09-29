import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../state/cart_controller.dart';
import '../../state/inventory_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import 'cart_panel.dart';
import 'product_tile.dart';

/// شاشەی فرۆشتن (POS): گەڕان/بارکۆد، تۆڕی کاڵاکان و سەبەتە.
/// English: the point-of-sale screen. On wide screens the cart sits next to the
/// grid; on phones it opens as a bottom sheet from the summary bar.
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    final String? error = context.read<CartController>().addProduct(product);
    if (error != null) AppDialogs.showMessage(context, error, isError: true);
  }

  /// گەڕان (یان بارکۆد) — ئەگەر یەک ئەنجام بوو، خودکار دەخرێتە سەبەتە.
  void _onSubmitted(String value) {
    final String needle = value.trim();
    if (needle.isEmpty) return;

    final InventoryController inventory = context.read<InventoryController>();
    Product? target = inventory.productByBarcode(needle);
    if (target == null) {
      final List<Product> matches = inventory.search(query: needle);
      if (matches.isEmpty) {
        AppDialogs.showMessage(
          context,
          AppStrings.productNotFound,
          isError: true,
        );
        return;
      }
      if (matches.length == 1) target = matches.first;
    }
    if (target != null) {
      _addToCart(target);
      _searchController.clear();
      setState(() => _query = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final InventoryController inventory = context.watch<InventoryController>();
    final CartController cart = context.watch<CartController>();
    final List<Product> products = inventory.search(
      query: _query,
      categoryId: _categoryId,
    );
    final bool wide = MediaQuery.sizeOf(context).width >= 1100;

    final Widget productsArea = Column(
      children: <Widget>[
        _buildSearchBar(context),
        _buildCategoryBar(context, inventory),
        Expanded(child: _buildGrid(context, inventory, products)),
      ],
    );

    if (wide) {
      return Row(
        children: <Widget>[
          Expanded(child: productsArea),
          const VerticalDivider(width: 1),
          const SizedBox(width: 380, child: CartPanel()),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Expanded(child: productsArea),
        _CartSummaryBar(cart: cart, onTap: () => _openCartSheet(context)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (String value) => setState(() => _query = value),
        onSubmitted: _onSubmitted,
        decoration: InputDecoration(
          hintText: AppStrings.searchProductOrBarcode,
          helperText: AppStrings.scanBarcode,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: AppStrings.close,
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(
    BuildContext context,
    InventoryController inventory,
  ) {
    final List<Category> categories = inventory.categories;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: Text(
                '${AppStrings.allCategories} '
                '(${inventory.activeProductCount})',
              ),
              selected: _categoryId.isEmpty,
              onSelected: (_) => setState(() => _categoryId = ''),
            ),
          ),
          ...categories.map(
            (Category category) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                avatar: Icon(category.icon, size: 16, color: category.color),
                label: Text(
                  '${category.name} '
                  '(${inventory.productCountInCategory(category.id)})',
                ),
                selected: _categoryId == category.id,
                onSelected: (_) => setState(
                  () => _categoryId =
                      _categoryId == category.id ? '' : category.id,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    InventoryController inventory,
    List<Product> products,
  ) {
    if (products.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_outlined,
        title: AppStrings.productNotFound,
        message: AppStrings.emptyCartHint,
      );
    }

    final CartController cart = context.watch<CartController>();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.98,
      ),
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        final Product product = products[index];
        return PosProductTile(
          product: product,
          category: inventory.categoryById(product.categoryId),
          quantityInCart: cart.quantityOf(product.id),
          onTap: () => _addToCart(product),
        );
      },
    );
  }

  Future<void> _openCartSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: CartPanel(),
      ),
    );
  }
}

/// شریتی کورتەی سەبەتە بۆ شاشە بچووکەکان.
class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar({required this.cart, required this.onTap});

  final CartController cart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Badge(
                label: Text('${cart.lineCount}'),
                isLabelVisible: cart.lineCount > 0,
                child: Icon(
                  Icons.shopping_cart_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.cart,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      settings.money(cart.total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${Formatters.quantity(cart.itemQuantity)} • '
                '${AppStrings.details}',
                style: theme.textTheme.labelMedium,
              ),
              const Icon(Icons.keyboard_arrow_up),
            ],
          ),
        ),
      ),
    );
  }
}
