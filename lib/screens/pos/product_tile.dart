import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../models/category.dart';
import '../../models/product.dart';

/// کارتی کاڵا لە شاشەی فرۆشتن (POS).
/// English: one tappable product tile in the POS grid. Shows how many are
/// already in the cart and blocks out-of-stock products.
class PosProductTile extends StatelessWidget {
  const PosProductTile({
    super.key,
    required this.product,
    required this.category,
    required this.quantityInCart,
    required this.onTap,
  });

  final Product product;
  final Category category;
  final double quantityInCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool outOfStock = product.isOutOfStock;
    final bool lowStock = product.isLowStock;
    final Color accent = category.color;

    return Card(
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        child: Opacity(
          opacity: outOfStock ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(category.icon, size: 16, color: accent),
                    ),
                    const Spacer(),
                    if (quantityInCart > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          Formatters.quantity(quantityInCart),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        Formatters.number(product.salePrice),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (outOfStock)
                      Text(
                        AppStrings.outOfStock,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Text(
                        '${Formatters.quantity(product.stock)} '
                        '${product.unit.shortLabel}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: lowStock
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              lowStock ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
