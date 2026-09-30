import 'package:flutter/foundation.dart' hide Category;

import '../models/app_user.dart';
import '../models/category.dart';
import '../models/held_cart.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';
import 'demo_data.dart';
import 'firestore_service.dart';
import 'local_storage.dart';

/// ڕیپۆزیتۆری سەرەکی سیستەم — پاشەکەوتکردن و خوێندنەوەی ڕاستەوخۆ لەگەڵ Firebase Firestore.
/// English: maps between models, Firestore cloud database, and local cache.
/// All operations (products, categories, sales, users, settings, sequences)
/// sync directly and immediately to Firebase Firestore.
class PosRepository {
  PosRepository(this._storage, [FirestoreService? firestore])
      : _firestore = firestore ?? FirestoreService();

  final LocalStorage _storage;
  final FirestoreService _firestore;

  FirestoreService get firestore => _firestore;

  /// دەستپێکردن و هاوکاتکردنی داتاکان لەگەڵ Firebase Firestore
  Future<void> initialize() async {
    try {
      final List<Map<String, dynamic>> remoteUsers =
          await _firestore.getCollection('users');
      final List<Map<String, dynamic>> remoteProds =
          await _firestore.getCollection('products');
      final List<Map<String, dynamic>> remoteCats =
          await _firestore.getCollection('categories');
      final List<Map<String, dynamic>> remoteSales =
          await _firestore.getCollection('sales');
      final Map<String, dynamic>? remoteSettings =
          await _firestore.getDocument('settings', 'store');
      final Map<String, dynamic>? remoteSeq =
          await _firestore.getDocument('sequences', 'invoices');

      // ئەگەر فایەرستۆر بەتاڵ بوو (یەکەم جار)، داتای سەرەتایی دەنێرێتە فایەربەیس
      if (remoteUsers.isEmpty && remoteProds.isEmpty) {
        await _seedToFirestore();
      } else {
        // فایەرستۆر داتای تێدایە، هەموو داتاکان دەهێنێتەوە
        if (remoteCats.isNotEmpty) {
          final List<Category> cats =
              remoteCats.map(Category.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.categoriesKey,
            cats.map((Category c) => c.toJson()).toList(),
          );
        }
        if (remoteProds.isNotEmpty) {
          final List<Product> prods =
              remoteProds.map(Product.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.productsKey,
            prods.map((Product p) => p.toJson()).toList(),
          );
        }
        if (remoteSales.isNotEmpty) {
          final List<Sale> sales =
              remoteSales.map(Sale.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.salesKey,
            sales.map((Sale s) => s.toJson()).toList(),
          );
        }
        if (remoteUsers.isNotEmpty) {
          final List<AppUser> users =
              remoteUsers.map(AppUser.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.usersKey,
            users.map((AppUser u) => u.toJson()).toList(),
          );
        }
        if (remoteSettings != null) {
          await _storage.writeMap(LocalStorage.settingsKey, remoteSettings);
        }
        if (remoteSeq != null && remoteSeq.containsKey('counter')) {
          final int count = (remoteSeq['counter'] as num?)?.toInt() ?? 0;
          await _storage.writeInt(LocalStorage.invoiceCounterKey, count);
        }
        await _storage.writeBool(LocalStorage.seededKey, true);
      }
    } catch (e) {
      debugPrint('PosRepository.initialize Firestore sync error: $e');
    }
  }

  // ── کاڵاکان ─────────────────────────────────────────────────────────────
  List<Product> loadProducts() => _storage
      .readList(LocalStorage.productsKey)
      .map(Product.fromJson)
      .toList(growable: false);

  Future<void> saveProducts(List<Product> products) async {
    final List<Product> oldProducts = loadProducts();
    final Set<String> newIds = products.map((Product p) => p.id).toSet();
    final List<String> deletedIds = oldProducts
        .where((Product p) => !newIds.contains(p.id))
        .map((Product p) => p.id)
        .toList();

    await _storage.writeList(
      LocalStorage.productsKey,
      products.map((Product product) => product.toJson()).toList(),
    );

    // پاشەکەوتکردنی ڕاستەوخۆ لەسەر فایەربەیس
    try {
      for (final String id in deletedIds) {
        _firestore.deleteDocument('products', id);
      }
      final List<Map<String, dynamic>> items =
          products.map((Product p) => p.toJson()).toList();
      await _firestore.saveBatch('products', items);
    } catch (e) {
      debugPrint('Firestore saveProducts error: $e');
    }
  }

  // ── پۆلەکان ─────────────────────────────────────────────────────────────
  List<Category> loadCategories() => _storage
      .readList(LocalStorage.categoriesKey)
      .map(Category.fromJson)
      .toList(growable: false);

  Future<void> saveCategories(List<Category> categories) async {
    final List<Category> oldCategories = loadCategories();
    final Set<String> newIds = categories.map((Category c) => c.id).toSet();
    final List<String> deletedIds = oldCategories
        .where((Category c) => !newIds.contains(c.id))
        .map((Category c) => c.id)
        .toList();

    await _storage.writeList(
      LocalStorage.categoriesKey,
      categories.map((Category category) => category.toJson()).toList(),
    );

    // پاشەکەوتکردنی ڕاستەوخۆ لەسەر فایەربەیس
    try {
      for (final String id in deletedIds) {
        _firestore.deleteDocument('categories', id);
      }
      final List<Map<String, dynamic>> items =
          categories.map((Category c) => c.toJson()).toList();
      await _firestore.saveBatch('categories', items);
    } catch (e) {
      debugPrint('Firestore saveCategories error: $e');
    }
  }

  // ── پسووڵەکان ───────────────────────────────────────────────────────────
  List<Sale> loadSales() => _storage
      .readList(LocalStorage.salesKey)
      .map(Sale.fromJson)
      .toList(growable: false);

  Future<void> saveSales(List<Sale> sales) async {
    await _storage.writeList(
      LocalStorage.salesKey,
      sales.map((Sale sale) => sale.toJson()).toList(),
    );

    // پاشەکەوتکردنی ڕاستەوخۆ لەسەر فایەربەیس
    try {
      final List<Map<String, dynamic>> items =
          sales.map((Sale s) => s.toJson()).toList();
      await _firestore.saveBatch('sales', items);
    } catch (e) {
      debugPrint('Firestore saveSales error: $e');
    }
  }

  // ── بەکارهێنەران ────────────────────────────────────────────────────────
  List<AppUser> loadUsers() => _storage
      .readList(LocalStorage.usersKey)
      .map(AppUser.fromJson)
      .toList(growable: false);

  Future<void> saveUsers(List<AppUser> users) async {
    final List<AppUser> oldUsers = loadUsers();
    final Set<String> newIds = users.map((AppUser u) => u.id).toSet();
    final List<String> deletedIds = oldUsers
        .where((AppUser u) => !newIds.contains(u.id))
        .map((AppUser u) => u.id)
        .toList();

    await _storage.writeList(
      LocalStorage.usersKey,
      users.map((AppUser user) => user.toJson()).toList(),
    );

    // پاشەکەوتکردنی ڕاستەوخۆ لەسەر فایەربەیس
    try {
      for (final String id in deletedIds) {
        _firestore.deleteDocument('users', id);
      }
      final List<Map<String, dynamic>> items =
          users.map((AppUser u) => u.toJson()).toList();
      await _firestore.saveBatch('users', items);
    } catch (e) {
      debugPrint('Firestore saveUsers error: $e');
    }
  }

  // ── سەبەتە هەڵواسراوەکان ────────────────────────────────────────────────
  List<HeldCart> loadHeldCarts() => _storage
      .readList(LocalStorage.heldCartsKey)
      .map(HeldCart.fromJson)
      .toList(growable: false);

  Future<void> saveHeldCarts(List<HeldCart> carts) async {
    await _storage.writeList(
      LocalStorage.heldCartsKey,
      carts.map((HeldCart cart) => cart.toJson()).toList(),
    );

    try {
      final List<Map<String, dynamic>> items =
          carts.map((HeldCart c) => c.toJson()).toList();
      await _firestore.saveBatch('held_carts', items);
    } catch (e) {
      debugPrint('Firestore saveHeldCarts error: $e');
    }
  }

  // ── ڕێکخستنەکان ─────────────────────────────────────────────────────────
  StoreSettings loadSettings() {
    final Map<String, dynamic>? json =
        _storage.readMap(LocalStorage.settingsKey);
    if (json == null) return const StoreSettings();
    return StoreSettings.fromJson(json);
  }

  Future<void> saveSettings(StoreSettings settings) async {
    await _storage.writeMap(LocalStorage.settingsKey, settings.toJson());

    // پاشەکەوتکردنی ڕاستەوخۆ لەسەر فایەربەیس
    try {
      await _firestore.setDocument('settings', 'store', settings.toJson());
    } catch (e) {
      debugPrint('Firestore saveSettings error: $e');
    }
  }

  // ── ژمێرەری پسووڵە ─────────────────────────────────────────────────────
  int nextInvoiceSequence() {
    final int current = _storage.readInt(LocalStorage.invoiceCounterKey);
    final int next = current + 1;
    _storage.writeInt(LocalStorage.invoiceCounterKey, next);

    // نوێکردنەوەی ژمێرەر لەسەر فایەربەیس
    try {
      _firestore.setDocument('sequences', 'invoices', <String, dynamic>{
        'counter': next,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firestore nextInvoiceSequence error: $e');
    }
    return next;
  }

  Future<void> saveInvoiceSequence(int value) async {
    await _storage.writeInt(LocalStorage.invoiceCounterKey, value);

    try {
      await _firestore.setDocument('sequences', 'invoices', <String, dynamic>{
        'counter': value,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firestore saveInvoiceSequence error: $e');
    }
  }

  // ── داتای نموونە ────────────────────────────────────────────────────────
  bool get hasSeeded => _storage.readBool(LocalStorage.seededKey);

  Future<void> markSeeded() => _storage.writeBool(LocalStorage.seededKey, true);

  Future<void> clearEverything() async {
    final List<Product> prods = loadProducts();
    final List<Category> cats = loadCategories();
    final List<Sale> sales = loadSales();
    final List<AppUser> users = loadUsers();

    await _storage.clearAll();

    try {
      for (final Product p in prods) {
        _firestore.deleteDocument('products', p.id);
      }
      for (final Category c in cats) {
        _firestore.deleteDocument('categories', c.id);
      }
      for (final Sale s in sales) {
        _firestore.deleteDocument('sales', s.id);
      }
      for (final AppUser u in users) {
        _firestore.deleteDocument('users', u.id);
      }
      _firestore.deleteDocument('settings', 'store');
      _firestore.deleteDocument('sequences', 'invoices');
    } catch (e) {
      debugPrint('Firestore clearEverything error: $e');
    }
  }

  Future<void> _seedToFirestore() async {
    final List<Category> cats = DemoData.categories();
    final List<Product> prods = DemoData.products();
    final List<Sale> sales = DemoData.sales(prods);
    final List<AppUser> users = DemoData.users();
    final StoreSettings settings = DemoData.settings;
    final int seq = sales.length;

    await saveCategories(cats);
    await saveProducts(prods);
    await saveSales(sales);
    await saveUsers(users);
    await saveSettings(settings);
    await saveInvoiceSequence(seq);
    await markSeeded();
  }
}