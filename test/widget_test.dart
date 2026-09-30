import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/models/analytics.dart';
import 'package:pos_system/models/product_unit.dart';
import 'package:pos_system/models/sale.dart';

void main() {
  group('Sale & Credit Debt Tests', () {
    test('Calculates credit debt correctly when partially paid', () {
      final Sale sale = Sale(
        id: 'INV-001',
        items: const <SaleItem>[
          SaleItem(
            productId: 'p1',
            name: 'شیر',
            unit: ProductUnit.piece,
            unitPrice: 1500,
            unitCost: 1000,
            quantity: 2,
          ),
        ],
        createdAt: DateTime.now(),
        cashierId: 'c1',
        cashierName: 'ئەحمەد',
        paidAmount: 1000,
        paymentMethod: PaymentMethod.credit,
        customerName: 'کاروان عەلی',
        customerPhone: '0770 123 4567',
      );

      expect(sale.total, 3000);
      expect(sale.paidAmount, 1000);
      expect(sale.isCredit, true);
      expect(sale.debtAmount, 2000);
      expect(sale.actualPaid, 1000);
      expect(sale.customerName, 'کاروان عەلی');
    });

    test('SaleSummary properly aggregates cash, card, and credit debt', () {
      final List<Sale> sales = <Sale>[
        Sale(
          id: 'INV-CASH',
          items: const <SaleItem>[
            SaleItem(
              productId: 'p1',
              name: 'ئاو',
              unit: ProductUnit.piece,
              unitPrice: 500,
              unitCost: 250,
              quantity: 2,
            ),
          ],
          createdAt: DateTime.now(),
          cashierId: 'c1',
          cashierName: 'ئەحمەد',
          paidAmount: 1000,
          paymentMethod: PaymentMethod.cash,
        ),
        Sale(
          id: 'INV-CREDIT',
          items: const <SaleItem>[
            SaleItem(
              productId: 'p2',
              name: 'برنج',
              unit: ProductUnit.piece,
              unitPrice: 4000,
              unitCost: 3000,
              quantity: 1,
            ),
          ],
          createdAt: DateTime.now(),
          cashierId: 'c1',
          cashierName: 'ئەحمەد',
          paidAmount: 1000,
          paymentMethod: PaymentMethod.credit,
          customerName: 'شوان محەمەد',
        ),
      ];

      final SaleSummary summary = SaleSummary.fromSales(sales);
      expect(summary.invoiceCount, 2);
      expect(summary.revenue, 5000); // 1000 + 4000
      expect(summary.cashRevenue, 2000); // 1000 pure cash + 1000 upfront credit
      expect(summary.cardRevenue, 0);
      expect(summary.creditDebt, 3000); // 4000 - 1000
      expect(summary.creditInvoiceCount, 1);
      expect(summary.collectedRevenue, 2000); // 1000 + 1000
    });
    test('Calculates Item Exchange and balance settlement (ساقی و باقی) correctly', () {
      // حاڵەتی ١: کڕیار کاڵای ٥٠٠٠ دیناری دەگەڕێنێتەوە و کاڵای ٨٠٠٠ دیناری دەبات (+٣٠٠٠ پێویستە بدات)
      final Sale exchangePositive = Sale(
        id: 'EXC-001',
        items: const <SaleItem>[
          SaleItem(
            productId: 'p_new',
            name: 'پانتۆڵ',
            unit: ProductUnit.piece,
            unitPrice: 8000,
            unitCost: 5000,
            quantity: 1,
          ),
          SaleItem(
            productId: 'p_ret',
            name: 'کراس (گەڕاوە)',
            unit: ProductUnit.piece,
            unitPrice: 5000,
            unitCost: 3000,
            quantity: -1,
          ),
        ],
        createdAt: DateTime.now(),
        cashierId: 'c1',
        cashierName: 'کاشێر',
        paidAmount: 3000,
        paymentMethod: PaymentMethod.cash,
        note: 'ئاڵوگۆڕ: گەڕاندنەوەی کراس و بردنی پانتۆڵ',
      );

      expect(exchangePositive.isExchange, true);
      expect(exchangePositive.total, 3000); // 8000 - 5000
      expect(exchangePositive.paidAmount, 3000);
      expect(exchangePositive.profit, 1000); // (8000 - 5000 profit) - (5000 - 3000 profit) = 3000 - 2000 = 1000

      // حاڵەتی ٢: کڕیار کاڵای ٦٠٠٠ دیناری دەگەڕێنێتەوە و کاڵای ٤٠٠٠ دیناری دەبات (-٢٠٠٠ دەگەڕێتەوە بۆ کڕیار)
      final Sale exchangeRefund = Sale(
        id: 'EXC-002',
        items: const <SaleItem>[
          SaleItem(
            productId: 'p_new2',
            name: 'تیشێرت',
            unit: ProductUnit.piece,
            unitPrice: 4000,
            unitCost: 2500,
            quantity: 1,
          ),
          SaleItem(
            productId: 'p_ret2',
            name: 'چاکەت (گەڕاوە)',
            unit: ProductUnit.piece,
            unitPrice: 6000,
            unitCost: 4000,
            quantity: -1,
          ),
        ],
        createdAt: DateTime.now(),
        cashierId: 'c1',
        cashierName: 'کاشێر',
        paidAmount: -2000,
        paymentMethod: PaymentMethod.cash,
      );

      expect(exchangeRefund.isExchange, true);
      expect(exchangeRefund.total, -2000); // 4000 - 6000 = -2000 (Refund)
    });
  });
}
