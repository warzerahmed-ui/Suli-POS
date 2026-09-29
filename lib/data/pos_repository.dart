import '../models/app_user.dart';
import '../models/category.dart';
import '../models/held_cart.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';
import 'local_storage.dart';

/// ڕیپۆزیتۆری سەرەکی سیستەم — خوێندنەوە و پاشەکەوتکردنی هەموو داتاکان.
///
/// English: maps between models and `LocalStorage`. Controllers only talk to
/// this class, never to `SharedPreferences` directly.
class PosRepository {
  PosRepository(this._storage);

  final LocalStorage _storage;

  // ── کاڵاکان ─────────────────────────────────────────────────────────────
  List<Product> loadProducts() => _storage
      .readList(LocalStorage.productsKey)
      .map(Product.fromJson)
      .toList(growable: false);

  Future<void> saveProducts(List<Product> products) => _storage.writeList(
        LocalStorage.productsKey,
        products.map((Product product) => product.toJson()).toList(),
      );

  // ── پۆلەکان ─────────────────────────────────────────────────────────────
  List<Category> loadCategories() => _storage
      .readList(LocalStorage.categoriesKey)
      .map(Category.fromJson)
      .toList(growable: false);

  Future<void> saveCategories(List<Category> categories) => _storage.writeList(
        LocalStorage.categoriesKey,
        categories.map((Category category) => category.toJson()).toList(),
      );

  // ── پسووڵەکان ───────────────────────────────────────────────────────────
  List<Sale> loadSales() => _storage
      .readList(LocalStorage.salesKey)
      .map(Sale.fromJson)
      .toList(growable: false);

  Future<void> saveSales(List<Sale> sales) => _storage.writeList(
        LocalStorage.salesKey,
        sales.map((Sale sale) => sale.toJson()).toList(),
      );

  // ── بەکارهێنەران ────────────────────────────────────────────────────────
  List<AppUser> loadUsers() => _storage
      .readList(LocalStorage.usersKey)
      .map(AppUser.fromJson)
      .toList(growable: false);

  Future<void> saveUsers(List<AppUser> users) => _storage.writeList(
        LocalStorage.usersKey,
        users.map((AppUser user) => user.toJson()).toList(),
      );

  // ── سەبەتە هەڵواسراوەکان ────────────────────────────────────────────────
  List<HeldCart> loadHeldCarts() => _storage
      .readList(LocalStorage.heldCartsKey)
      .map(HeldCart.fromJson)
      .toList(growable: false);

  Future<void> saveHeldCarts(List<HeldCart> carts) => _storage.writeList(
        LocalStorage.heldCartsKey,
        carts.map((HeldCart cart) => cart.toJson()).toList(),
      );

  // ── ڕێکخستنەکان ─────────────────────────────────────────────────────────
  StoreSettings loadSettings() {
    final Map<String, dynamic>? json =
        _storage.readMap(LocalStorage.settingsKey);
    if (json == null) return const StoreSettings();
    return StoreSettings.fromJson(json);
  }

  Future<void> saveSettings(StoreSettings settings) =>
      _storage.writeMap(LocalStorage.settingsKey, settings.toJson());

  // ── ژمێرەری پسووڵە ─────────────────────────────────────────────────────
  int nextInvoiceSequence() {
    final int current = _storage.readInt(LocalStorage.invoiceCounterKey);
    final int next = current + 1;
    _storage.writeInt(LocalStorage.invoiceCounterKey, next);
    return next;
  }

  /// دانانی ژمێرەرەکە بۆ ژمارەیەکی دیاریکراو (بۆ نموونە دوای بارکردنی داتای نموونە).
  Future<void> saveInvoiceSequence(int value) =>
      _storage.writeInt(LocalStorage.invoiceCounterKey, value);

  // ── داتای نموونە ────────────────────────────────────────────────────────
  bool get hasSeeded => _storage.readBool(LocalStorage.seededKey);

  Future<void> markSeeded() => _storage.writeBool(LocalStorage.seededKey, true);

  Future<void> clearEverything() => _storage.clearAll();
}
