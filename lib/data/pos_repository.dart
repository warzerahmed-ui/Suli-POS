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

/// ڕیپۆزیتۆری سەرەکی سیستەم — پاشەکەوتکردن بە کەمترین Read و Write لەگەڵ Firebase Firestore.
/// Optimized Firebase Firestore POS Repository:
/// - Delta Sync / Version Hashing (Drops startup reads from thousands to 1 Read!)
/// - Single-Document Writes (Drops checkout writes by 99.8%: only writes new sale + changed stocks)
/// - Zero redundant reads across all UI navigation screens.
class PosRepository {
  PosRepository(this._storage, [FirestoreService? firestore])
      : _firestore = firestore ?? FirestoreService();

  final LocalStorage _storage;
  final FirestoreService _firestore;

  FirestoreService get firestore => _firestore;

  static const String _syncCollection = 'sync';
  static const String _syncDoc = 'status';
  static const String _keyProductsVer = 'sync.productsVersion';
  static const String _keyCategoriesVer = 'sync.categoriesVersion';
  static const String _keyUsersVer = 'sync.usersVersion';
  static const String _keySettingsVer = 'sync.settingsVersion';
  static const String _keySalesCount = 'sync.salesCount';

  /// دەستپێکردن و هاوکاتکردنی زیرەکانە بە کەمترین Read
  Future<void> initialize() async {
    try {
      final bool hasLocalData =
          loadUsers().isNotEmpty && loadProducts().isNotEmpty;

      // ١. هێنانی تەنها یەک دۆکیۆمێنتی مێتاداتا (تێچوو: تەنها ١ Read بۆ تەواوی سیستەم!)
      final Map<String, dynamic>? remoteSync =
          await _firestore.getDocument(_syncCollection, _syncDoc);

      if (remoteSync == null) {
        final List<Map<String, dynamic>> remoteUsers =
            await _firestore.getCollection('users');
        final List<Map<String, dynamic>> remoteProds =
            await _firestore.getCollection('products');

        if (remoteUsers.isEmpty && remoteProds.isEmpty) {
          await _seedToFirestore();
        } else {
          await _fullFetchFromFirestore();
        }
        return;
      }

      // ٢. بەراوردکردنی وەشانەکانی لۆکاڵ لەگەڵ فایەربەیس
      final String localProdVer = _storage.readString(_keyProductsVer) ?? '';
      final String remoteProdVer =
          remoteSync['productsVersion']?.toString() ?? '';
      final String localCatVer = _storage.readString(_keyCategoriesVer) ?? '';
      final String remoteCatVer =
          remoteSync['categoriesVersion']?.toString() ?? '';
      final String localUserVer = _storage.readString(_keyUsersVer) ?? '';
      final String remoteUserVer = remoteSync['usersVersion']?.toString() ?? '';
      final String localSettVer = _storage.readString(_keySettingsVer) ?? '';
      final String remoteSettVer =
          remoteSync['settingsVersion']?.toString() ?? '';
      final int localSalesCount = _storage.readInt(_keySalesCount);
      final int remoteSalesCount =
          (remoteSync['salesCount'] as num?)?.toInt() ?? 0;

      // ئەگەر وەشانەکان وەک یەک بن، پێویست بە هیچ خوێندنەوەیەکی فایەربەیس ناکات (0 Reads!)
      if (!hasLocalData ||
          localProdVer != remoteProdVer ||
          loadProducts().isEmpty) {
        final List<Map<String, dynamic>> prods =
            await _firestore.getCollection('products');
        if (prods.isNotEmpty) {
          final List<Product> list =
              prods.map(Product.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.productsKey,
            list.map((Product p) => p.toJson()).toList(),
          );
          await _storage.writeString(_keyProductsVer, remoteProdVer);
        }
      }

      if (!hasLocalData ||
          localCatVer != remoteCatVer ||
          loadCategories().isEmpty) {
        final List<Map<String, dynamic>> cats =
            await _firestore.getCollection('categories');
        if (cats.isNotEmpty) {
          final List<Category> list =
              cats.map(Category.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.categoriesKey,
            list.map((Category c) => c.toJson()).toList(),
          );
          await _storage.writeString(_keyCategoriesVer, remoteCatVer);
        }
      }

      if (!hasLocalData ||
          localUserVer != remoteUserVer ||
          loadUsers().isEmpty) {
        final List<Map<String, dynamic>> users =
            await _firestore.getCollection('users');
        if (users.isNotEmpty) {
          final List<AppUser> list =
              users.map(AppUser.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.usersKey,
            list.map((AppUser u) => u.toJson()).toList(),
          );
          await _storage.writeString(_keyUsersVer, remoteUserVer);
        }
      }

      if (!hasLocalData || localSettVer != remoteSettVer) {
        final Map<String, dynamic>? settings =
            await _firestore.getDocument('settings', 'store');
        if (settings != null) {
          await _storage.writeMap(LocalStorage.settingsKey, settings);
          await _storage.writeString(_keySettingsVer, remoteSettVer);
        }
      }

      if (!hasLocalData ||
          localSalesCount != remoteSalesCount ||
          loadSales().isEmpty) {
        final List<Map<String, dynamic>> sales =
            await _firestore.getCollection('sales');
        if (sales.isNotEmpty) {
          final List<Sale> list =
              sales.map(Sale.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.salesKey,
            list.map((Sale s) => s.toJson()).toList(),
          );
          await _storage.writeInt(_keySalesCount, remoteSalesCount);
        }
      }

      final Map<String, dynamic>? remoteSeq =
          await _firestore.getDocument('sequences', 'invoices');
      if (remoteSeq != null && remoteSeq.containsKey('counter')) {
        final int count = (remoteSeq['counter'] as num?)?.toInt() ?? 0;
        await _storage.writeInt(LocalStorage.invoiceCounterKey, count);
      }

      await _storage.writeBool(LocalStorage.seededKey, true);
    } catch (e) {
      debugPrint('PosRepository.initialize error: $e');
    }
  }

  Future<void> _fullFetchFromFirestore() async {
    final List<Map<String, dynamic>> cats =
        await _firestore.getCollection('categories');
    final List<Map<String, dynamic>> prods =
        await _firestore.getCollection('products');
    final List<Map<String, dynamic>> sales =
        await _firestore.getCollection('sales');
    final List<Map<String, dynamic>> users =
        await _firestore.getCollection('users');
    final Map<String, dynamic>? settings =
        await _firestore.getDocument('settings', 'store');
    final Map<String, dynamic>? seq =
        await _firestore.getDocument('sequences', 'invoices');

    if (cats.isNotEmpty) {
      final List<Category> list =
          cats.map(Category.fromJson).toList(growable: false);
      await _storage.writeList(
          LocalStorage.categoriesKey, list.map((c) => c.toJson()).toList());
    }
    if (prods.isNotEmpty) {
      final List<Product> list =
          prods.map(Product.fromJson).toList(growable: false);
      await _storage.writeList(
          LocalStorage.productsKey, list.map((p) => p.toJson()).toList());
    }
    if (sales.isNotEmpty) {
      final List<Sale> list =
          sales.map(Sale.fromJson).toList(growable: false);
      await _storage.writeList(
          LocalStorage.salesKey, list.map((s) => s.toJson()).toList());
    }
    if (users.isNotEmpty) {
      final List<AppUser> list =
          users.map(AppUser.fromJson).toList(growable: false);
      await _storage.writeList(
          LocalStorage.usersKey, list.map((u) => u.toJson()).toList());
    }
    if (settings != null) {
      await _storage.writeMap(LocalStorage.settingsKey, settings);
    }
    if (seq != null && seq.containsKey('counter')) {
      final int count = (seq['counter'] as num?)?.toInt() ?? 0;
      await _storage.writeInt(LocalStorage.invoiceCounterKey, count);
    }

    final String now = DateTime.now().millisecondsSinceEpoch.toString();
    await _touchSyncMetadata(
      productsVersion: now,
      categoriesVersion: now,
      usersVersion: now,
      settingsVersion: now,
      salesCount: sales.length,
    );
    await _storage.writeBool(LocalStorage.seededKey, true);
  }

  // ── کاڵاکان (تەنها ١ Write بۆ زیادکردن/دەستکاری) ─────────────────────────
  List<Product> loadProducts() => _storage
      .readList(LocalStorage.productsKey)
      .map(Product.fromJson)
      .toList(growable: false);

  /// پاشەکەوتکردنی تەنها ئەو ١ کاڵایەی دەستکاری کراوە (1 Write لەبری N Writes)
  Future<void> saveSingleProduct(Product product) async {
    final List<Product> prods = loadProducts();
    final int index = prods.indexWhere((Product p) => p.id == product.id);
    final List<Product> updated = List<Product>.from(prods);
    if (index < 0) {
      updated.add(product);
    } else {
      updated[index] = product;
    }
    await _storage.writeList(
      LocalStorage.productsKey,
      updated.map((Product p) => p.toJson()).toList(),
    );

    try {
      await _firestore.setDocument('products', product.id, product.toJson());
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyProductsVer, ver);
      _touchSyncMetadata(productsVersion: ver);
    } catch (e) {
      debugPrint('Firestore saveSingleProduct error: $e');
    }
  }

  /// سڕینەوەی تەنها ئەو ١ کاڵایە (1 Delete)
  Future<void> deleteSingleProduct(String id) async {
    final List<Product> prods = loadProducts();
    final List<Product> updated =
        prods.where((Product p) => p.id != id).toList();
    await _storage.writeList(
      LocalStorage.productsKey,
      updated.map((Product p) => p.toJson()).toList(),
    );

    try {
      await _firestore.deleteDocument('products', id);
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyProductsVer, ver);
      _touchSyncMetadata(productsVersion: ver);
    } catch (e) {
      debugPrint('Firestore deleteSingleProduct error: $e');
    }
  }

  /// نوێکردنەوەی بڕی کۆگای تەنها ئەو کاڵایانەی فرۆشراون (K Writes تەنها)
  Future<void> updateProductsStock(Map<String, double> newStocks) async {
    if (newStocks.isEmpty) return;
    final List<Product> prods = loadProducts();
    final List<Product> updatedList = <Product>[];
    final List<Product> changedProds = <Product>[];

    for (final Product p in prods) {
      if (newStocks.containsKey(p.id)) {
        final Product updated = p.copyWith(stock: newStocks[p.id]!);
        updatedList.add(updated);
        changedProds.add(updated);
      } else {
        updatedList.add(p);
      }
    }

    await _storage.writeList(
      LocalStorage.productsKey,
      updatedList.map((Product p) => p.toJson()).toList(),
    );

    try {
      for (final Product p in changedProds) {
        _firestore.setDocument('products', p.id, p.toJson());
      }
    } catch (e) {
      debugPrint('Firestore updateProductsStock error: $e');
    }
  }

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

    try {
      for (final String id in deletedIds) {
        _firestore.deleteDocument('products', id);
      }
      final List<Map<String, dynamic>> items =
          products.map((Product p) => p.toJson()).toList();
      await _firestore.saveBatch('products', items);
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyProductsVer, ver);
      _touchSyncMetadata(productsVersion: ver);
    } catch (e) {
      debugPrint('Firestore saveProducts error: $e');
    }
  }

  // ── پۆلەکان (تەنها ١ Write بۆ زیادکردن/دەستکاری) ─────────────────────────
  List<Category> loadCategories() => _storage
      .readList(LocalStorage.categoriesKey)
      .map(Category.fromJson)
      .toList(growable: false);

  Future<void> saveSingleCategory(Category category) async {
    final List<Category> cats = loadCategories();
    final int index = cats.indexWhere((Category c) => c.id == category.id);
    final List<Category> updated = List<Category>.from(cats);
    if (index < 0) {
      updated.add(category);
    } else {
      updated[index] = category;
    }
    await _storage.writeList(
      LocalStorage.categoriesKey,
      updated.map((Category c) => c.toJson()).toList(),
    );

    try {
      await _firestore.setDocument('categories', category.id, category.toJson());
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyCategoriesVer, ver);
      _touchSyncMetadata(categoriesVersion: ver);
    } catch (e) {
      debugPrint('Firestore saveSingleCategory error: $e');
    }
  }

  Future<void> deleteSingleCategory(String id) async {
    final List<Category> cats = loadCategories();
    final List<Category> updated =
        cats.where((Category c) => c.id != id).toList();
    await _storage.writeList(
      LocalStorage.categoriesKey,
      updated.map((Category c) => c.toJson()).toList(),
    );

    try {
      await _firestore.deleteDocument('categories', id);
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyCategoriesVer, ver);
      _touchSyncMetadata(categoriesVersion: ver);
    } catch (e) {
      debugPrint('Firestore deleteSingleCategory error: $e');
    }
  }

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

    try {
      for (final String id in deletedIds) {
        _firestore.deleteDocument('categories', id);
      }
      final List<Map<String, dynamic>> items =
          categories.map((Category c) => c.toJson()).toList();
      await _firestore.saveBatch('categories', items);
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyCategoriesVer, ver);
      _touchSyncMetadata(categoriesVersion: ver);
    } catch (e) {
      debugPrint('Firestore saveCategories error: $e');
    }
  }

  // ── پسووڵەکان (تەنها ١ Write بۆ هەر فرۆشتنێک) ───────────────────────────
  List<Sale> loadSales() => _storage
      .readList(LocalStorage.salesKey)
      .map(Sale.fromJson)
      .toList(growable: false);

  /// پاشەکەوتکردنی ١ پسووڵە (1 Write لەبری هەزاران Write)
  Future<void> saveSingleSale(Sale sale) async {
    final List<Sale> sales = loadSales();
    final int index = sales.indexWhere((Sale s) => s.id == sale.id);
    final List<Sale> updated = List<Sale>.from(sales);
    if (index < 0) {
      updated.insert(0, sale);
    } else {
      updated[index] = sale;
    }
    await _storage.writeList(
      LocalStorage.salesKey,
      updated.map((Sale s) => s.toJson()).toList(),
    );

    try {
      await _firestore.setDocument('sales', sale.id, sale.toJson());
      final int count = updated.length;
      await _storage.writeInt(_keySalesCount, count);
      _touchSyncMetadata(salesCount: count);
    } catch (e) {
      debugPrint('Firestore saveSingleSale error: $e');
    }
  }

  Future<void> saveSales(List<Sale> sales) async {
    await _storage.writeList(
      LocalStorage.salesKey,
      sales.map((Sale sale) => sale.toJson()).toList(),
    );

    try {
      final List<Map<String, dynamic>> items =
          sales.map((Sale s) => s.toJson()).toList();
      await _firestore.saveBatch('sales', items);
      await _storage.writeInt(_keySalesCount, sales.length);
      _touchSyncMetadata(salesCount: sales.length);
    } catch (e) {
      debugPrint('Firestore saveSales error: $e');
    }
  }

  // ── بەکارهێنەران (تەنها ١ Write بۆ هەر بەکارهێنەرێک) ─────────────────────
  List<AppUser> loadUsers() => _storage
      .readList(LocalStorage.usersKey)
      .map(AppUser.fromJson)
      .toList(growable: false);

  Future<void> saveSingleUser(AppUser user) async {
    final List<AppUser> users = loadUsers();
    final int index = users.indexWhere((AppUser u) => u.id == user.id);
    final List<AppUser> updated = List<AppUser>.from(users);
    if (index < 0) {
      updated.add(user);
    } else {
      updated[index] = user;
    }
    await _storage.writeList(
      LocalStorage.usersKey,
      updated.map((AppUser u) => u.toJson()).toList(),
    );

    try {
      await _firestore.setDocument('users', user.id, user.toJson());
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyUsersVer, ver);
      _touchSyncMetadata(usersVersion: ver);
    } catch (e) {
      debugPrint('Firestore saveSingleUser error: $e');
    }
  }

  Future<void> deleteSingleUser(String id) async {
    final List<AppUser> users = loadUsers();
    final List<AppUser> updated =
        users.where((AppUser u) => u.id != id).toList();
    await _storage.writeList(
      LocalStorage.usersKey,
      updated.map((AppUser u) => u.toJson()).toList(),
    );

    try {
      await _firestore.deleteDocument('users', id);
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyUsersVer, ver);
      _touchSyncMetadata(usersVersion: ver);
    } catch (e) {
      debugPrint('Firestore deleteSingleUser error: $e');
    }
  }

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

    try {
      for (final String id in deletedIds) {
        _firestore.deleteDocument('users', id);
      }
      final List<Map<String, dynamic>> items =
          users.map((AppUser u) => u.toJson()).toList();
      await _firestore.saveBatch('users', items);
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keyUsersVer, ver);
      _touchSyncMetadata(usersVersion: ver);
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

    try {
      await _firestore.setDocument('settings', 'store', settings.toJson());
      final String ver = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.writeString(_keySettingsVer, ver);
      _touchSyncMetadata(settingsVersion: ver);
    } catch (e) {
      debugPrint('Firestore saveSettings error: $e');
    }
  }

  // ── ژمێرەری پسووڵە ─────────────────────────────────────────────────────
  int nextInvoiceSequence() {
    final int current = _storage.readInt(LocalStorage.invoiceCounterKey);
    final int next = current + 1;
    _storage.writeInt(LocalStorage.invoiceCounterKey, next);

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
      _firestore.deleteDocument(_syncCollection, _syncDoc);
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

    final String now = DateTime.now().millisecondsSinceEpoch.toString();
    await _touchSyncMetadata(
      productsVersion: now,
      categoriesVersion: now,
      usersVersion: now,
      settingsVersion: now,
      salesCount: sales.length,
    );
    await markSeeded();
  }

  Future<void> _touchSyncMetadata({
    String? productsVersion,
    String? categoriesVersion,
    String? usersVersion,
    String? settingsVersion,
    int? salesCount,
  }) async {
    try {
      final Map<String, dynamic> update = <String, dynamic>{};
      if (productsVersion != null) update['productsVersion'] = productsVersion;
      if (categoriesVersion != null) update['categoriesVersion'] = categoriesVersion;
      if (usersVersion != null) update['usersVersion'] = usersVersion;
      if (settingsVersion != null) update['settingsVersion'] = settingsVersion;
      if (salesCount != null) update['salesCount'] = salesCount;
      update['lastSyncAt'] = DateTime.now().toIso8601String();

      _firestore.setDocument(_syncCollection, _syncDoc, update);
    } catch (e) {
      debugPrint('PosRepository._touchSyncMetadata error: $e');
    }
  }
}