import '../core/formatters.dart';
import 'sale.dart';

/// کورتەی فرۆشتنەکان (داهات، قازانج، ژمارەی پسووڵە ...).
/// English: aggregate numbers used by the dashboard and report screens.
class SaleSummary {
  const SaleSummary({
    this.revenue = 0,
    this.cost = 0,
    this.invoiceCount = 0,
    this.itemQuantity = 0,
    this.cashRevenue = 0,
    this.cardRevenue = 0,
    this.creditDebt = 0,
    this.creditInvoiceCount = 0,
  });

  final double revenue;
  final double cost;
  final int invoiceCount;
  final double itemQuantity;
  final double cashRevenue;
  final double cardRevenue;
  final double creditDebt;
  final int creditInvoiceCount;

  /// داهاتی دەستبەجێی وەرگیراو (نەقد + کارت).
  double get collectedRevenue => cashRevenue + cardRevenue;

  double get profit => revenue - cost;

  double get averageInvoice => invoiceCount == 0 ? 0 : revenue / invoiceCount;

  double get profitMargin => revenue == 0 ? 0 : (profit / revenue) * 100;

  static SaleSummary fromSales(Iterable<Sale> sales) {
    double revenue = 0;
    double cost = 0;
    double quantity = 0;
    double cash = 0;
    double card = 0;
    double debt = 0;
    int count = 0;
    int creditCount = 0;

    for (final Sale sale in sales) {
      if (sale.isVoided) continue;
      revenue += sale.total;
      cost += sale.totalCost;
      quantity += sale.itemQuantity;
      count++;

      if (sale.paymentMethod == PaymentMethod.card) {
        card += sale.actualPaid;
      } else {
        cash += sale.actualPaid;
      }

      if (sale.isCredit) {
        debt += sale.debtAmount;
        if (sale.debtAmount > 0) creditCount++;
      }
    }

    return SaleSummary(
      revenue: revenue,
      cost: cost,
      invoiceCount: count,
      itemQuantity: quantity,
      cashRevenue: cash,
      cardRevenue: card,
      creditDebt: debt,
      creditInvoiceCount: creditCount,
    );
  }
}

/// کارکردی کاڵایەک لە ماوەیەکی دیاریکراودا.
class ProductPerformance {
  const ProductPerformance({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });

  final String productId;
  final String name;
  final double quantity;
  final double revenue;
  final double profit;

  /// زۆرترین فرۆشراوەکان (بەپێی بڕی فرۆشراو).
  static List<ProductPerformance> topFromSales(
    Iterable<Sale> sales, {
    int limit = 5,
  }) {
    final Map<String, ProductPerformance> map = <String, ProductPerformance>{};
    for (final Sale sale in sales) {
      if (sale.isVoided) continue;
      for (final SaleItem item in sale.items) {
        final ProductPerformance? existing = map[item.productId];
        map[item.productId] = ProductPerformance(
          productId: item.productId,
          name: item.name,
          quantity: (existing?.quantity ?? 0) + item.quantity,
          revenue: (existing?.revenue ?? 0) + item.total,
          profit: (existing?.profit ?? 0) + item.profit,
        );
      }
    }
    final List<ProductPerformance> result = map.values.toList()
      ..sort((ProductPerformance a, ProductPerformance b) =>
          b.quantity.compareTo(a.quantity));
    return result.take(limit).toList();
  }
}

/// خاڵێکی هێڵکاری: فرۆشتنی یەک ڕۆژ.
class DailyPoint {
  const DailyPoint({
    required this.day,
    required this.revenue,
    required this.cost,
    required this.invoiceCount,
  });

  final DateTime day;
  final double revenue;
  final double cost;
  final int invoiceCount;

  double get profit => revenue - cost;

  String get label => Formatters.weekdayShort(day);

  /// لیستی ڕۆژانە بۆ ماوەی دیاریکراو (ڕۆژە بێ فرۆشتنەکان بە سفر دێن).
  static List<DailyPoint> forRange(
    Iterable<Sale> sales, {
    required DateTime from,
    required DateTime to,
  }) {
    final List<DateTime> days = Formatters.daysBetween(from, to);
    final Map<String, List<Sale>> grouped = <String, List<Sale>>{};
    for (final Sale sale in sales) {
      if (sale.isVoided) continue;
      grouped
          .putIfAbsent(Formatters.isoDate(sale.createdAt), () => <Sale>[])
          .add(sale);
    }
    return days.map((DateTime day) {
      final List<Sale> daySales = grouped[Formatters.isoDate(day)] ?? <Sale>[];
      final SaleSummary summary = SaleSummary.fromSales(daySales);
      return DailyPoint(
        day: day,
        revenue: summary.revenue,
        cost: summary.cost,
        invoiceCount: summary.invoiceCount,
      );
    }).toList();
  }
}

/// فرۆشتنی کاشێرێک.
class CashierPerformance {
  const CashierPerformance({
    required this.cashierId,
    required this.name,
    required this.revenue,
    required this.invoiceCount,
    required this.profit,
  });

  final String cashierId;
  final String name;
  final double revenue;
  final int invoiceCount;
  final double profit;

  static List<CashierPerformance> fromSales(Iterable<Sale> sales) {
    final Map<String, CashierPerformance> map = <String, CashierPerformance>{};
    for (final Sale sale in sales) {
      if (sale.isVoided) continue;
      final CashierPerformance? existing = map[sale.cashierId];
      map[sale.cashierId] = CashierPerformance(
        cashierId: sale.cashierId,
        name: sale.cashierName,
        revenue: (existing?.revenue ?? 0) + sale.total,
        invoiceCount: (existing?.invoiceCount ?? 0) + 1,
        profit: (existing?.profit ?? 0) + sale.profit,
      );
    }
    final List<CashierPerformance> result = map.values.toList()
      ..sort((CashierPerformance a, CashierPerformance b) =>
          b.revenue.compareTo(a.revenue));
    return result;
  }
}
