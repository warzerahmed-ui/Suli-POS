import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/analytics.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../state/auth_controller.dart';
import '../state/inventory_controller.dart';
import '../state/sales_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/bar_chart.dart';
import 'sale_detail_screen.dart';

/// داشبۆرد — کورتەی ئەمڕۆ، هێڵکاری حەفتە، دوایین فرۆشتن و ئاگاداری کۆگا.
/// English: the dashboard with today's numbers, a 7-day chart, the latest
/// invoices and the low-stock alerts.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesController sales = context.watch<SalesController>();
    final InventoryController inventory = context.watch<InventoryController>();
    final SettingsController settings = context.watch<SettingsController>();
    final bool isAdmin = context.watch<AuthController>().isAdmin;

    final SaleSummary today = sales.todaySummary;
    final List<DailyPoint> week = sales.dailyPoints(days: 7);
    final List<Product> lowStock = inventory.lowStockProducts;
    final List<Sale> recent = sales.recent(limit: 5);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _StatsGrid(
          cards: <Widget>[
            StatCard(
              title: AppStrings.todaySales,
              value: settings.money(today.revenue),
              icon: Icons.payments_outlined,
              color: AppColors.primary,
              hint: '${AppStrings.todayInvoices}: ${today.invoiceCount}',
            ),
            StatCard(
              title: AppStrings.itemsSold,
              value: _compact(today.itemQuantity),
              icon: Icons.shopping_basket_outlined,
              color: StatusColors.info(context),
              hint: '${AppStrings.averageInvoice}: '
                  '${settings.money(today.averageInvoice)}',
            ),
            if (isAdmin)
              StatCard(
                title: AppStrings.todayProfit,
                value: settings.money(today.profit),
                icon: Icons.trending_up,
                color: StatusColors.success(context),
                hint: '${AppStrings.profitMargin}: '
                    '${today.profitMargin.toStringAsFixed(1)}%',
              ),
            StatCard(
              title: AppStrings.todayDebt,
              value: settings.money(today.creditDebt),
              icon: Icons.account_balance_wallet_outlined,
              color: today.creditDebt > 0
                  ? StatusColors.warning(context)
                  : Theme.of(context).colorScheme.outline,
              hint: '${AppStrings.creditSales}: ${today.creditInvoiceCount}',
            ),
            if (isAdmin)
              StatCard(
                title: AppStrings.inventoryValue,
                value: settings.money(inventory.inventoryValue),
                icon: Icons.warehouse_outlined,
                color: AppColors.secondary,
                hint: '${AppStrings.productCount}: '
                    '${inventory.activeProductCount}',
              ),
            StatCard(
              title: AppStrings.lowStockItems,
              value: '${lowStock.length}',
              icon: Icons.warning_amber_outlined,
              color: StatusColors.warning(context),
              hint: AppStrings.stockAlerts,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: AppStrings.weeklySales,
          subtitle: '${AppStrings.revenue} / ${AppStrings.profit}',
          child: SimpleBarChart(
            height: 220,
            points: week
                .map(
                  (DailyPoint point) => BarChartPoint(
                    label: point.label,
                    value: point.revenue,
                    secondary: point.profit,
                  ),
                )
                .toList(),
            formatValue: _compact,
            secondaryColor: StatusColors.success(context),
          ),
        ),
        const SizedBox(height: 16),
        _RecentSalesCard(sales: recent, settings: settings),
        const SizedBox(height: 16),
        _LowStockCard(products: lowStock),
      ],
    );
  }
}

/// شێوەیەکی کورت بۆ ژمارە گەورەکان لە هێڵکاریدا (1.2M / 12k).
String _compact(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}k';
  }
  return value.toStringAsFixed(0);
}

/// ڕیزکردنی کارتەکانی ئامار بەپێی پانی شاشە.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 1200
            ? 4
            : (width >= 860 ? 3 : (width >= 560 ? 2 : 1));
        const double spacing = 12;
        final double itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((Widget card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

/// دوایین فرۆشتنەکان.
class _RecentSalesCard extends StatelessWidget {
  const _RecentSalesCard({required this.sales, required this.settings});

  final List<Sale> sales;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SectionCard(
      title: AppStrings.recentSales,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: sales.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.noReceipts,
            )
          : Column(
              children: sales.map((Sale sale) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          sale.id,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (sale.isCredit) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sale.customerName.isNotEmpty
                                ? '${AppStrings.credit}: ${sale.customerName}'
                                : AppStrings.credit,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    sale.isCredit && sale.debtAmount > 0
                        ? '${Formatters.dateTime(sale.createdAt)} • ${AppStrings.remainingDebt}: ${settings.money(sale.debtAmount)}'
                        : '${Formatters.dateTime(sale.createdAt)} • ${sale.cashierName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    settings.money(sale.total),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          SaleDetailScreen(saleId: sale.id),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// ئاگادارییەکانی کۆگا — کاڵاکانی کەم.
class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color warning = StatusColors.warning(context);
    final Color danger = StatusColors.danger(context);

    return SectionCard(
      title: AppStrings.stockAlerts,
      subtitle: products.isEmpty ? AppStrings.allStockOk : null,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: products.isEmpty
          ? const EmptyState(
              icon: Icons.verified_outlined,
              title: AppStrings.allStockOk,
            )
          : Column(
              children: products.take(6).map((Product product) {
                final Color color = product.isOutOfStock ? danger : warning;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        size: 18, color: color),
                  ),
                  title: Text(
                    product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${AppStrings.remainingStock}: '
                    '${Formatters.quantity(product.stock)} '
                    '${product.unit.shortLabel} • '
                    '${AppStrings.lowStockThreshold}: '
                    '${Formatters.quantity(product.lowStockThreshold)}',
                  ),
                  trailing: Chip(
                    label: Text(
                      product.isOutOfStock
                          ? AppStrings.outOfStock
                          : Formatters.quantity(product.stock),
                    ),
                    labelStyle: TextStyle(color: color),
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    backgroundColor: color.withValues(alpha: 0.1),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
