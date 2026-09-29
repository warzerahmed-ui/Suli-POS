import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/analytics.dart';
import '../models/sale.dart';
import '../state/sales_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/bar_chart.dart';

/// ماوەی ڕاپۆرت.
enum _RangeKind { today, week, month, all, custom }

/// شاشەی ڕاپۆرتەکان: داهات، قازانج، زۆرترین فرۆشراو و هەناردەکردنی CSV.
/// English: the reports screen — everything the owner needs to read the numbers.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _RangeKind _kind = _RangeKind.week;
  DateTimeRange? _customRange;

  DateTimeRange get _range {
    final DateTime now = DateTime.now();
    switch (_kind) {
      case _RangeKind.today:
        return DateTimeRange(start: now, end: now);
      case _RangeKind.week:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case _RangeKind.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _RangeKind.all:
        return DateTimeRange(start: DateTime(2000), end: now);
      case _RangeKind.custom:
        return _customRange ?? DateTimeRange(start: now, end: now);
    }
  }

  String _label(_RangeKind kind) {
    switch (kind) {
      case _RangeKind.today:
        return AppStrings.today;
      case _RangeKind.week:
        return AppStrings.thisWeek;
      case _RangeKind.month:
        return AppStrings.thisMonth;
      case _RangeKind.all:
        return AppStrings.allTime;
      case _RangeKind.custom:
        return AppStrings.customRange;
    }
  }

  Future<void> _pickCustomRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _kind = _RangeKind.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SalesController sales = context.watch<SalesController>();
    final SettingsController settings = context.watch<SettingsController>();

    final DateTimeRange range = _range;
    final List<Sale> rangeSales = sales.salesInRange(range.start, range.end);
    final SaleSummary summary = sales.summaryOf(rangeSales);
    final List<ProductPerformance> topProducts =
        ProductPerformance.topFromSales(rangeSales, limit: 8);
    final List<CashierPerformance> cashiers =
        CashierPerformance.fromSales(rangeSales);
    final List<DailyPoint> points = DailyPoint.forRange(
      sales.sales,
      from: range.start,
      to: range.end,
    );
    final List<DailyPoint> chartPoints = points.length > 31
        ? points.sublist(points.length - 31)
        : points;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ..._RangeKind.values
                .where((_RangeKind kind) => kind != _RangeKind.custom)
                .map(
                  (_RangeKind kind) => ChoiceChip(
                    label: Text(_label(kind)),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
                ),
            OutlinedButton.icon(
              onPressed: _pickCustomRange,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _kind == _RangeKind.custom
                    ? '${Formatters.date(range.start)} — '
                        '${Formatters.date(range.end)}'
                    : AppStrings.customRange,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => exportSalesCsv(context, rangeSales),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text(AppStrings.exportCsv),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _statCard(
              context,
              AppStrings.revenue,
              settings.money(summary.revenue),
              Icons.payments_outlined,
              AppColors.primary,
            ),
            _statCard(
              context,
              AppStrings.totalCost,
              settings.money(summary.cost),
              Icons.shopping_bag_outlined,
              StatusColors.info(context),
            ),
            _statCard(
              context,
              AppStrings.profit,
              settings.money(summary.profit),
              Icons.trending_up,
              StatusColors.success(context),
            ),
            _statCard(
              context,
              AppStrings.invoice,
              '${summary.invoiceCount}',
              Icons.receipt_long_outlined,
              AppColors.secondary,
            ),
            _statCard(
              context,
              AppStrings.averageInvoice,
              settings.money(summary.averageInvoice),
              Icons.calculate_outlined,
              StatusColors.warning(context),
            ),
            _statCard(
              context,
              AppStrings.quantitySold,
              Formatters.quantity(summary.itemQuantity),
              Icons.inventory_2_outlined,
              AppColors.primaryDark,
            ),
            _statCard(
              context,
              AppStrings.totalDebt,
              settings.money(summary.creditDebt),
              Icons.account_balance_wallet_outlined,
              summary.creditDebt > 0
                  ? StatusColors.warning(context)
                  : Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PaymentBreakdownCard(summary: summary, settings: settings),
        const SizedBox(height: 16),
        SectionCard(
          title: AppStrings.salesByDay,
          subtitle: '${AppStrings.revenue} / ${AppStrings.profit}',
          child: chartPoints.isEmpty
              ? const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: AppStrings.noSalesInRange,
                )
              : SimpleBarChart(
                  height: 240,
                  formatValue: _compact,
                  secondaryColor: StatusColors.success(context),
                  points: chartPoints
                      .map(
                        (DailyPoint point) => BarChartPoint(
                          label: point.label,
                          value: point.revenue,
                          secondary: point.profit,
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _TopProductsCard(products: topProducts, settings: settings),
        const SizedBox(height: 16),
        _CashiersCard(cashiers: cashiers, settings: settings),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 240,
      child: StatCard(title: title, value: value, icon: icon, color: color),
    );
  }

  static String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

/// زۆرترین فرۆشراوەکان.
class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products, required this.settings});

  final List<ProductPerformance> products;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color success = StatusColors.success(context);

    return SectionCard(
      title: AppStrings.topProducts,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: products.isEmpty
          ? const EmptyState(
              icon: Icons.insights_outlined,
              title: AppStrings.noSalesInRange,
            )
          : Column(
              children: products.asMap().entries.map(
                    (MapEntry<int, ProductPerformance> entry) {
                      final int rank = entry.key + 1;
                      final ProductPerformance item = entry.value;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          child: Text(
                            '$rank',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${AppStrings.quantitySold}: '
                          '${Formatters.quantity(item.quantity)} • '
                          '${AppStrings.revenue}: '
                          '${settings.money(item.revenue)}',
                        ),
                        trailing: Text(
                          settings.money(item.profit),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: success,
                          ),
                        ),
                      );
                    },
                  ).toList(),
            ),
    );
  }
}

/// فرۆشتن بەپێی کاشێر.
class _CashiersCard extends StatelessWidget {
  const _CashiersCard({required this.cashiers, required this.settings});

  final List<CashierPerformance> cashiers;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color success = StatusColors.success(context);

    return SectionCard(
      title: AppStrings.byCashier,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: cashiers.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline,
              title: AppStrings.noSalesInRange,
            )
          : Column(
              children: cashiers.map((CashierPerformance item) {
                return ListTile(
                  leading: CircleAvatar(child: Text(item.name.substring(0, 1))),
                  title: Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${AppStrings.invoice}: ${item.invoiceCount} • '
                    '${AppStrings.profit}: ${settings.money(item.profit)}',
                  ),
                  trailing: Text(
                    settings.money(item.revenue),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: success,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// هەناردەکردنی پسووڵەکان وەک CSV بۆ کلیپبۆرد.
///
/// English: CSV export through the clipboard — works on desktop, mobile and the
/// web without needing file-system permissions.
Future<void> exportSalesCsv(BuildContext context, List<Sale> sales) async {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln(
    'invoice,datetime,cashier,customer,phone,lines,subtotal,discount,tax,total,paid,debt,cost,'
    'profit,payment,status',
  );
  for (final Sale sale in sales) {
    buffer.writeln(
      <String>[
        sale.id,
        Formatters.isoDateTime(sale.createdAt),
        '"${sale.cashierName}"',
        '"${sale.customerName}"',
        '"${sale.customerPhone}"',
        '${sale.lineCount}',
        sale.subtotal.toStringAsFixed(2),
        sale.safeDiscount.toStringAsFixed(2),
        sale.taxAmount.toStringAsFixed(2),
        sale.total.toStringAsFixed(2),
        sale.paidAmount.toStringAsFixed(2),
        sale.debtAmount.toStringAsFixed(2),
        sale.totalCost.toStringAsFixed(2),
        sale.profit.toStringAsFixed(2),
        sale.paymentMethod.name,
        sale.isVoided ? 'voided' : 'completed',
      ].join(','),
    );
  }

  await Clipboard.setData(ClipboardData(text: buffer.toString()));
  if (!context.mounted) return;
  AppDialogs.showMessage(context, AppStrings.csvCopied);
}

/// کورتەی شێوازەکانی پارەدان (نەقد، کارت، قەرز).
class _PaymentBreakdownCard extends StatelessWidget {
  const _PaymentBreakdownCard({
    required this.summary,
    required this.settings,
  });

  final SaleSummary summary;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SectionCard(
      title: AppStrings.paymentBreakdown,
      child: Column(
        children: <Widget>[
          _item(
            context,
            title: AppStrings.cashSales,
            amount: summary.cashRevenue,
            icon: Icons.payments_outlined,
            color: AppColors.primary,
          ),
          const Divider(height: 16),
          _item(
            context,
            title: AppStrings.cardSales,
            amount: summary.cardRevenue,
            icon: Icons.credit_card_outlined,
            color: StatusColors.info(context),
          ),
          const Divider(height: 16),
          _item(
            context,
            title: AppStrings.totalDebt,
            amount: summary.creditDebt,
            icon: Icons.account_balance_wallet_outlined,
            color: summary.creditDebt > 0
                ? theme.colorScheme.error
                : theme.colorScheme.outline,
            subtitle: '${summary.creditInvoiceCount} ${AppStrings.invoice}',
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          settings.money(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
