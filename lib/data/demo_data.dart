import 'dart:math';

import '../core/formatters.dart';
import '../core/password_hasher.dart';
import '../models/app_user.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';

/// داتای نموونە بۆ ئەوەی سیستەمەکە بەتاڵ دەرنەکەوێت لە یەکەم بەکارهێناندا.
///
/// English: deterministic demo data (categories, products, staff and one week
/// of sales) so dashboard/report screens are meaningful right after install.
class DemoData {
  const DemoData._();

  static const String _adminId = 'user-admin';
  static const String _adminName = 'بەڕێوەبەری سیستەم';
  static const String _cashierId = 'user-cashier';
  static const String _cashierName = 'کاروان ئەحمەد';

  static List<Category> categories() => const <Category>[
        Category(id: 'cat-dairy', name: 'شیرەمەنی', iconKey: 'dairy', colorValue: 0xFF2E7D32),
        Category(id: 'cat-bakery', name: 'نان و بەحەک', iconKey: 'bakery', colorValue: 0xFF795548),
        Category(id: 'cat-beverage', name: 'خواردنەوە', iconKey: 'beverage', colorValue: 0xFF1565C0),
        Category(id: 'cat-water', name: 'ئاوی خواردنەوە', iconKey: 'water', colorValue: 0xFF0288D1),
        Category(id: 'cat-fruit', name: 'سەوزە و میوە', iconKey: 'fruit', colorValue: 0xFF558B2F),
        Category(id: 'cat-snacks', name: 'خواردنی سووک', iconKey: 'snacks', colorValue: 0xFFEF6C00),
        Category(id: 'cat-cleaning', name: 'پاککەرەوە', iconKey: 'cleaning', colorValue: 0xFF6A1B9A),
        Category(id: 'cat-hygiene', name: 'پاکوخاوێنی', iconKey: 'hygiene', colorValue: 0xFFAD1457),
      ];

  static Product _p({
    required String id,
    required String name,
    required String barcode,
    required String categoryId,
    required double cost,
    required double price,
    required double stock,
    ProductUnit unit = ProductUnit.piece,
    double threshold = 6,
  }) {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      categoryId: categoryId,
      unit: unit,
      costPrice: cost,
      salePrice: price,
      stock: stock,
      lowStockThreshold: threshold,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  static List<Product> products() => <Product>[
        _p(id: 'p-001', name: 'شیرێکی تەواو ١ لیتر', barcode: '6291001001', categoryId: 'cat-dairy', cost: 1250, price: 1500, stock: 48, unit: ProductUnit.liter),
        _p(id: 'p-002', name: 'ماستی سروشتی ٥٠٠ گرام', barcode: '6291001002', categoryId: 'cat-dairy', cost: 1000, price: 1250, stock: 30),
        _p(id: 'p-003', name: 'پەنیری سپی ١ کگ', barcode: '6291001003', categoryId: 'cat-dairy', cost: 5500, price: 7000, stock: 14, unit: ProductUnit.kilogram),
        _p(id: 'p-004', name: 'هێلکە (کارتۆن ٣٠ دانە)', barcode: '6291001004', categoryId: 'cat-dairy', cost: 4800, price: 5500, stock: 12, unit: ProductUnit.box, threshold: 4),
        _p(id: 'p-005', name: 'نان (١٠ دانە)', barcode: '6291002001', categoryId: 'cat-bakery', cost: 1000, price: 1500, stock: 25, unit: ProductUnit.pack),
        _p(id: 'p-006', name: 'کێکی کاکێو', barcode: '6291002002', categoryId: 'cat-bakery', cost: 750, price: 1000, stock: 40),
        _p(id: 'p-007', name: 'شەکەرە (١ کارتۆن)', barcode: '6291002003', categoryId: 'cat-bakery', cost: 3200, price: 4000, stock: 18, unit: ProductUnit.box),
        _p(id: 'p-008', name: 'چای سیا ٤٠٠ گرام', barcode: '6291003001', categoryId: 'cat-beverage', cost: 3500, price: 4500, stock: 22),
        _p(id: 'p-009', name: 'قاوەی نائارام ٢٠٠ گرام', barcode: '6291003002', categoryId: 'cat-beverage', cost: 5200, price: 6500, stock: 10),
        _p(id: 'p-010', name: 'شەربەتی پرتەقاڵ ١ لیتر', barcode: '6291003003', categoryId: 'cat-beverage', cost: 1500, price: 2000, stock: 36, unit: ProductUnit.liter),
        _p(id: 'p-011', name: 'ئاوی کانزا ٦٦٠ مل (پاکەتی ٦)', barcode: '6291004001', categoryId: 'cat-water', cost: 1400, price: 2000, stock: 50, unit: ProductUnit.pack),
        _p(id: 'p-012', name: 'ئاوی کانزا ١.٥ لیتر', barcode: '6291004002', categoryId: 'cat-water', cost: 600, price: 800, stock: 4, unit: ProductUnit.liter, threshold: 10),
        _p(id: 'p-013', name: 'کاڵە بەڕەنگ (١٠٠ گرام)', barcode: '6291005001', categoryId: 'cat-fruit', cost: 900, price: 1200, stock: 8, unit: ProductUnit.kilogram),
        _p(id: 'p-014', name: 'بامە (کگ)', barcode: '6291005002', categoryId: 'cat-fruit', cost: 3500, price: 4500, stock: 2, unit: ProductUnit.kilogram, threshold: 5),
        _p(id: 'p-015', name: 'شریتۆی بەرهەم (٣٢ گرام)', barcode: '6291006001', categoryId: 'cat-snacks', cost: 500, price: 750, stock: 120),
        _p(id: 'p-016', name: 'بیسکێتی چاکلێت', barcode: '6291006002', categoryId: 'cat-snacks', cost: 1000, price: 1500, stock: 60),
        _p(id: 'p-017', name: 'گوێزە (١٠٠ گرام)', barcode: '6291006003', categoryId: 'cat-snacks', cost: 1200, price: 1700, stock: 35, unit: ProductUnit.kilogram),
        _p(id: 'p-018', name: 'سابوونی دەستشۆر', barcode: '6291007001', categoryId: 'cat-cleaning', cost: 1800, price: 2500, stock: 26),
        _p(id: 'p-019', name: 'پاککەرەوەی قامیش', barcode: '6291007002', categoryId: 'cat-cleaning', cost: 4000, price: 5000, stock: 15, unit: ProductUnit.liter),
        _p(id: 'p-020', name: 'پاکەتی کاغەزی سەفە', barcode: '6291008001', categoryId: 'cat-hygiene', cost: 1100, price: 1600, stock: 5, unit: ProductUnit.pack, threshold: 12),
        _p(id: 'p-021', name: 'کاتانەی زانەیی', barcode: '6291008002', categoryId: 'cat-hygiene', cost: 700, price: 1000, stock: 44),
        _p(id: 'p-022', name: 'تووتی سەروو', barcode: '6291008003', categoryId: 'cat-hygiene', cost: 2200, price: 3000, stock: 9),
      ];

  /// ٧ ڕۆژی ڕابردوو فرۆشتنی نموونە دروست دەکات (بەبێ کەمکردنەوەی کۆگا).
  static List<Sale> sales(List<Product> products, {DateTime? now}) {
    if (products.isEmpty) return <Sale>[];
    final DateTime today = Formatters.startOfDay(now ?? DateTime.now());
    final Random random = Random(11);
    final List<Sale> result = <Sale>[];
    int sequence = 0;

    for (int dayOffset = 6; dayOffset >= 0; dayOffset--) {
      final DateTime day = today.subtract(Duration(days: dayOffset));
      final int invoiceCount = 3 + random.nextInt(4);
      for (int invoiceIndex = 0; invoiceIndex < invoiceCount; invoiceIndex++) {
        final int lineCount = 1 + random.nextInt(4);
        final Set<String> usedProducts = <String>{};
        final List<SaleItem> items = <SaleItem>[];

        for (int line = 0; line < lineCount; line++) {
          final Product product = products[random.nextInt(products.length)];
          if (!usedProducts.add(product.id)) continue;
          final double quantity = product.unit.allowsFractions
              ? (1 + random.nextInt(4)) / 2
              : (1 + random.nextInt(3)).toDouble();
          items.add(
            SaleItem(
              productId: product.id,
              name: product.name,
              unit: product.unit,
              unitPrice: product.salePrice,
              unitCost: product.costPrice,
              quantity: quantity,
            ),
          );
        }
        if (items.isEmpty) continue;

        sequence++;
        final DateTime createdAt = day.add(
          Duration(hours: 9 + random.nextInt(11), minutes: random.nextInt(60)),
        );
        final bool soldByCashier = random.nextBool();
        final double subtotal = items.fold<double>(
          0,
          (double sum, SaleItem item) => sum + item.total,
        );

        result.add(
          Sale(
            id: 'INV-${Formatters.isoDate(createdAt).replaceAll('-', '')}'
                '-${sequence.toString().padLeft(4, '0')}',
            items: items,
            createdAt: createdAt,
            cashierId: soldByCashier ? _cashierId : _adminId,
            cashierName: soldByCashier ? _cashierName : _adminName,
            paidAmount: subtotal,
            paymentMethod:
                random.nextInt(5) == 0 ? PaymentMethod.card : PaymentMethod.cash,
          ),
        );
      }
    }
    return result;
  }

  /// بەکارهێنەرەکانی نموونە (بەڕێوەبەر + کاشێر).
  static List<AppUser> users() => <AppUser>[
        AppUser.defaultAdmin(),
        AppUser(
          id: _cashierId,
          fullName: _cashierName,
          username: 'cashier',
          passwordHash: PasswordHasher.hash('cashier123'),
          createdAt: DateTime(2026, 1, 2),
        ),
      ];

  static const StoreSettings settings = StoreSettings(
    storeName: 'مارکێتی نموونە',
    phone: '0750 000 0000',
    address: 'هەولێر - شەقامی سەرەکی',
    receiptFooter: 'سوپاس بۆ کڕینەکەت — بەخێر بێیتەوە',
  );
}
