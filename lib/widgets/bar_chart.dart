import 'package:flutter/material.dart';

/// خاڵێکی هێڵکاری ستوونی.
/// English: one bar of the chart (a day, a category, a cashier ...).
class BarChartPoint {
  const BarChartPoint({
    required this.label,
    required this.value,
    this.secondary,
  });

  final String label;
  final double value;

  /// بەهای دووەم (بۆ نموونە قازانج لەگەڵ داهات).
  final double? secondary;
}

/// هێڵکاری ستوونی ساکار — بێ پاکێجی دەرەکی.
/// English: lightweight bar chart built with plain widgets so the app does not
/// need a charting dependency for a simple dashboard.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.points,
    required this.formatValue,
    this.height = 200,
    this.primaryColor,
    this.secondaryColor,
  });

  final List<BarChartPoint> points;
  final String Function(double value) formatValue;
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = primaryColor ?? theme.colorScheme.primary;
    final Color secondary = secondaryColor ?? theme.colorScheme.secondary;
    final bool hasSecondary =
        points.any((BarChartPoint point) => (point.secondary ?? 0) > 0);

    double maxValue = 0;
    for (final BarChartPoint point in points) {
      if (point.value > maxValue) maxValue = point.value;
      final double second = point.secondary ?? 0;
      if (second > maxValue) maxValue = second;
    }

    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '—',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: points.map((BarChartPoint point) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: _bar(
                            context,
                            value: point.value,
                            maxValue: maxValue,
                            color: primary,
                          ),
                        ),
                        if (hasSecondary) ...<Widget>[
                          const SizedBox(width: 3),
                          Expanded(
                            child: _bar(
                              context,
                              value: point.secondary ?? 0,
                              maxValue: maxValue,
                              color: secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatValue(point.value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    point.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bar(
    BuildContext context, {
    required double value,
    required double maxValue,
    required Color color,
  }) {
    final double factor =
        maxValue <= 0 ? 0 : (value / maxValue).clamp(0.0, 1.0).toDouble();
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: factor == 0 ? 0.002 : factor,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}
