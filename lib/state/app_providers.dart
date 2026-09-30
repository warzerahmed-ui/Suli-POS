import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../data/local_storage.dart';
import '../data/pos_repository.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';
import 'inventory_controller.dart';
import 'sales_controller.dart';
import 'settings_controller.dart';

/// Ú©Û†Ú©Ø±Ø§ÙˆÛ•ÛŒ Ù‡Û•Ù…ÙˆÙˆ Ú©Û†Ù†ØªØ±Û†ÚµÛ•Ø±Û•Ú©Ø§Ù† + Ø¯Ø§Ø¨ÛŒÙ†Ú©Ø±Ø¯Ù†ÛŒ Ø¯Ø§ØªØ§ÛŒ Ø³Û•Ø±Û•ØªØ§ÛŒÛŒ.
///
/// English: composition root. `bootstrap()` opens the storage, seeds demo data
/// on the very first run and returns every controller wired together.
class AppProviders {
  AppProviders(this.repository)
      : settings = SettingsController(repository),
        auth = AuthController(repository),
        inventory = InventoryController(repository),
        cart = CartController(repository),
        sales = SalesController(repository);

  final PosRepository repository;
  final SettingsController settings;
  final AuthController auth;
  final InventoryController inventory;
  final CartController cart;
  final SalesController sales;

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
    cart.setTaxPercent(settings.settings.taxPercent);
  }

  void _syncTaxWithSettings() =>
      cart.setTaxPercent(settings.settings.taxPercent);

  /// Ø¨Ø§Ø±Ú©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø¯Ø§ØªØ§ÛŒ Ù†Ù…ÙˆÙˆÙ†Û• (Ù„Û• Ú•ÙˆÙˆÚ©Ø§Ø±ÛŒ Ú•ÛŽÚ©Ø®Ø³ØªÙ†Û•Ú©Ø§Ù†Û•ÙˆÛ•).
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
    cart.resetAfterSale();
    auth.load();
    settings.load();
  }

  /// Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ù‡Û•Ù…ÙˆÙˆ Ø¯Ø§ØªØ§ Ùˆ Ú¯Û•Ú•Ø§Ù†Û•ÙˆÛ• Ø¨Û† Ø¯Û†Ø®ÛŒ Ø³Û•Ø±Û•ØªØ§.
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

  List<Object> _notifiers() => <Object>[settings, auth, inventory, cart, sales];

  void dispose() {
    for (final Object notifier in _notifiers()) {
      if (notifier is ChangeNotifier) notifier.dispose();
    }
  }
}
