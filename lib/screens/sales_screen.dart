import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/analytics.dart';
import '../models/sale.dart';
import '../state/auth_controller.dart';
import '../state/sales_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import 'sale_detail_screen.dart';

/// ماوەی بەرواری هەڵبژێردراو لە شاشەی پسووڵەکان.
enum _RangePreset { today, yesterday, week, month, all, custom }

/// شاشەی پسووڵەکان: فلتەری بەروار، گەڕان و کورتەی ماوەکە.
/// English: invoice history with quick date filters and a range summary.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();

  _RangePreset _preset = _RangePreset.today;
  DateTimeRange? _customRange;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTimeRange get _range {
    final DateTime now = DateTime.now();
    switch (_preset) {
      case _RangePreset.today:
        return DateTimeRange(start: now, end: now);
      case _RangePreset.yesterday:
        final DateTime yesterday = now.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case _RangePreset.week:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case _RangePreset.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _RangePreset.all:
        return DateTimeRange(start: DateTime(2000), end: now);
      case _RangePreset.custom:
        return _customRange ?? DateTimeRange(start: now, end: now);
    }
  }

  String _presetLabel(_RangePreset preset) {
    switch (preset) {
      case _RangePreset.today:
        return AppStrings.today;
      case _RangePreset.yesterday:
        return AppStrings.yesterday;
      case _RangePreset.week:
        return AppStrings.thisWeek;
      case _RangePreset.month:
        return AppStrings.thisMonth;
      case _RangePreset.all:
        return AppStrings.allTime;
      case _RangePreset.custom:
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
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _preset = _RangePreset.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SalesController sales = context.watch<SalesController>();
    final SettingsController settings = context.watch<SettingsController>();
    final bool isAdmin = context.watch<AuthController>().isAdmin;

    final DateTimeRange range = _range;
    final List<Sale> inRange =
        sales.salesInRange(range.start, range.end, includeVoided: true);
    final List<Sale> filtered = sales.search(_query, source: inRange);
    final SaleSummary summary = sales.summaryOf(inRange);

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
                        hintText: AppStrings.searchInvoice,
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _pickCustomRange,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _preset == _RangePreset.custom
                          ? '${Formatters.date(range.start)} — '
                              '${Formatters.date(range.end)}'
                          : AppStrings.dateRange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _RangePreset.values
                      .where((_RangePreset preset) =>
                          preset != _RangePreset.custom)
                      .map(
                        (_RangePreset preset) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(_presetLabel(preset)),
                            selected: _preset == preset,
                            onSelected: (_) =>
                                setState(() => _preset = preset),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  title: AppStrings.revenue,
                  value: settings.money(summary.revenue),
                  icon: Icons.payments_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: AppStrings.invoice,
                  value: '${summary.invoiceCount}',
                  icon: Icons.receipt_long_outlined,
                  color: StatusColors.info(context),
                ),
              ),
              if (isAdmin) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: AppStrings.profit,
                    value: settings.money(summary.profit),
                    icon: Icons.trending_up,
                    color: StatusColors.success(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: AppStrings.noReceipts,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) =>
                      _SaleTile(sale: filtered[index]),
                ),
        ),
      ],
    );
  }
}

/// کارتی پسووڵەیەک لە لیستەکە.
class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sale.isVoided
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(
            sale.isVoided ? Icons.undo : Icons.receipt_long,
            size: 20,
            color: sale.isVoided
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.primary,
          ),
        ),
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                sale.id,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (sale.isVoided)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Chip(
                  label: const Text(AppStrings.voided),
                  labelStyle: theme.textTheme.labelSmall,
                  backgroundColor: theme.colorScheme.errorContainer,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${Formatters.dateTime(sale.createdAt)} • ${sale.cashierName} • '
            '${Formatters.quantity(sale.itemQuantity)} '
            '${AppStrings.quantity}',
            maxLines: 2,
          ),
        ),
        trailing: Text(
          settings.money(sale.total),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                SaleDetailScreen(saleId: sale.id),
          ),
        ),
      ),
    );
  }
}
