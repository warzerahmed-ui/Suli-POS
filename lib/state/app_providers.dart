import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../data/local_storage.dart';
import '../data/pos_repository.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';
import 'customer_controller.dart';
import 'expenses_controller.dart';
import 'inventory_controller.dart';
import 'sales_controller.dart';
import 'settings_controller.dart';
import 'shift_controller.dart';

/// کۆکراوەی هەموو کۆنترۆڵەرەکان + دابینکردنی داتای سەرەتایی.
///
/// English: composition root. `bootstrap()` opens the storage, seeds demo data
/// on the very first run and returns every controller wired together.
class AppProviders {
  AppProviders(this.repository)
    : settings = SettingsController(repository),
      auth = AuthController(repository),
      inventory = InventoryController(repository),
      cart = CartController(repository),
      sales = SalesController(repository),
      customer = CustomerController(repository),
      expenses = ExpensesController(repository),
      shift = ShiftController(repository);

  final PosRepository repository;
  final SettingsController settings;
  final AuthController auth;
  final InventoryController inventory;
  final CartController cart;
  final SalesController sales;
  final CustomerController customer;
  final ExpensesController expenses;
  final ShiftController shift;

  static Future<AppProviders> bootstrap() async {
    final LocalStorage storage = await LocalStorage.open();
    final PosRepository repository = PosRepository(storage);
    await repository.initialize();
    if (!repository.hasSeeded) {
      await _seed(repository);
    }
    final AppProviders providers = AppProviders(repository);
    providers._loadAll();
    providers.settings.addListener(providers._syncTaxWithSettings);
    return providers;
  }

  void _loadAll() {
    settings.load();
    auth.load();
    inventory.load();
    sales.load();
    cart.load();
    customer.load();
    cart.setTaxPercent(settings.settings.taxPercent);
  }

  void _syncTaxWithSettings() =>
      cart.setTaxPercent(settings.settings.taxPercent);

  /// بارکردنەوەی داتای نموونە (لە ڕووکاری ڕێکخستنەکانەوە).
  Future<void> loadDemoData() async {
    final List<Product> products = DemoData.products();
    final List<Sale> demoSales = DemoData.sales(products);
    await repository.saveCategories(DemoData.categories());
    await repository.saveProducts(products);
    await repository.saveSales(demoSales);
    await repository.saveUsers(DemoData.users());
    await repository.saveSettings(DemoData.settings);
    await repository.saveInvoiceSequence(demoSales.length);
    await repository.markSeeded();
    inventory.load();
    sales.load();
    cart.load();
    customer.load();
    cart.resetAfterSale();
    auth.load();
    settings.load();
  }

  /// سڕینەوەی هەموو داتا و گەڕانەوە بۆ دۆخی سەرەتا.
  Future<void> resetAll() async {
    await repository.clearEverything();
    await _seed(repository);
    _loadAll();
    auth.signOut();
    cart.resetAfterSale();
  }

  static Future<void> _seed(PosRepository repository) async {
    final List<Product> products = DemoData.products();
    final List<Sale> sales = DemoData.sales(products);
    await repository.saveCategories(DemoData.categories());
    await repository.saveProducts(products);
    await repository.saveSales(sales);
    await repository.saveUsers(DemoData.users());
    await repository.saveSettings(DemoData.settings);
    await repository.saveInvoiceSequence(sales.length);
    await repository.markSeeded();
  }

  List<Object> _notifiers() => <Object>[
    settings,
    auth,
    inventory,
    cart,
    sales,
    customer,
  ];

  void dispose() {
    for (final Object notifier in _notifiers()) {
      if (notifier is ChangeNotifier) notifier.dispose();
    }
  }
}

