import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;

import '../models/app_user.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/held_cart.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';
import 'demo_data.dart';
import 'firestore_service.dart';
import 'local_storage.dart';

/// ڕیپۆزیتۆری سەرەکی سیستەم — کارکردنی ئۆفلاینی تەواو (Offline-First Architecture).
/// لەکاتی نەبوونی ئینتەرنێت بەهیچ جۆرێک کار ناوەستێت:
/// ١. هەموو فرۆشتن و دەستکارییەک دەستبەجێ لە لۆکاڵ تۆمار دەکرێت.
/// ٢. ئەگەر ئینتەرنێت نەبوو، دەخرێتە ناو (Offline Sync Queue).
/// ٣. لەگەڵ پەیدابوونەوەی ئینتەرنێت، خۆکارانە (Auto-Sync) هەمووی دەنێرێتە سەر فایەربەیس.
class PosRepository {
  PosRepository(this._storage, [FirestoreService? firestore])
      : _firestore = firestore ?? FirestoreService() {
    _initPendingCount();
    _startAutoSyncTimer();
  }

  final LocalStorage _storage;
  final FirestoreService _firestore;

  FirestoreService get firestore => _firestore;

  static const String _syncCollection = 'sync';
  static const String _syncDoc = 'status';
  static const String _keyProductsVer = 'sync.productsVersion';
  static const String _keyCategoriesVer = 'sync.categoriesVersion';
  static const String _keyUsersVer = 'sync.usersVersion';
  static const String _keySettingsVer = 'sync.settingsVersion';
  static const String _keyCustomersVer = 'sync.customersVersion';
  static const String _keySalesCount = 'sync.salesCount';
  static const String _keyOfflineQueue = 'pos.offline_queue';

  /// نیشاندەری دۆخی پەیوەندی بە فایەربەیس
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  /// ژمارەی ئەو مامەڵانەی لە ئۆفلایندا ئەنجامدراون و چاوەڕێی ناردنن بۆ فایەربەیس
  final ValueNotifier<int> pendingSyncCountNotifier = ValueNotifier<int>(0);

  Timer? _autoSyncTimer;

  void _initPendingCount() {
    final List<Map<String, dynamic>> queue =
        _storage.readList(_keyOfflineQueue);
    pendingSyncCountNotifier.value = queue.length;
    if (queue.isNotEmpty) {
      isOnlineNotifier.value = false;
    }
  }

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    // پشکنینی خۆکارانە هەموو ٢٠ چرکە جارێک بۆ ناردنی داتا ئۆفلاینەکان
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (pendingSyncCountNotifier.value > 0) {
        syncPendingQueue();
      }
    });
  }

  void dispose() {
    _autoSyncTimer?.cancel();
    isOnlineNotifier.dispose();
    pendingSyncCountNotifier.dispose();
  }

  // ── Offline Queue Management ──────────────────────────────────────────────

  void _enqueueOfflineAction({
    required String action,
    required String collection,
    required String documentId,
    Map<String, dynamic>? data,
  }) {
    final List<Map<String, dynamic>> queue =
        _storage.readList(_keyOfflineQueue);
    final Map<String, dynamic> item = <String, dynamic>{
      'id': 'act-${DateTime.now().microsecondsSinceEpoch}',
      'action': action,
      'collection': collection,
      'documentId': documentId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final int existingIndex = queue.indexWhere(
      (Map<String, dynamic> q) =>
          q['collection'] == collection && q['documentId'] == documentId,
    );
    if (existingIndex >= 0) {
      queue[existingIndex] = item;
    } else {
      queue.add(item);
    }

    _storage.writeList(_keyOfflineQueue, queue);
    pendingSyncCountNotifier.value = queue.length;
    isOnlineNotifier.value = false;
  }

  /// ناردنی هەموو داتاکانی ڕیزبەندی ئۆفلاین بۆ فایەربەیس (Sync Flush)
  Future<int> syncPendingQueue() async {
    final List<Map<String, dynamic>> queue =
        _storage.readList(_keyOfflineQueue);
    if (queue.isEmpty) {
      pendingSyncCountNotifier.value = 0;
      isOnlineNotifier.value = true;
      return 0;
    }

    int syncedCount = 0;
    final List<Map<String, dynamic>> remaining = <Map<String, dynamic>>[];

    for (final Map<String, dynamic> item in queue) {
      final String action = item['action'] as String? ?? 'set';
      final String collection = item['collection'] as String? ?? '';
      final String docId = item['documentId'] as String? ?? '';
      final dynamic dataRaw = item['data'];
      final Map<String, dynamic>? data =
          dataRaw is Map ? Map<String, dynamic>.from(dataRaw) : null;

      bool success = false;
      try {
        if (action == 'delete') {
          success = await _firestore.deleteDocument(collection, docId);
        } else if (data != null) {
          success = await _firestore.setDocument(collection, docId, data);
        }
      } catch (e) {
        success = false;
      }

      if (success) {
        syncedCount++;
      } else {
        remaining.add(item);
      }
    }

    await _storage.writeList(_keyOfflineQueue, remaining);
    pendingSyncCountNotifier.value = remaining.length;
    isOnlineNotifier.value = remaining.isEmpty;

    if (syncedCount > 0) {
      final String now = DateTime.now().millisecondsSinceEpoch.toString();
      _touchSyncMetadata(
        productsVersion: now,
        categoriesVersion: now,
        usersVersion: now,
        settingsVersion: now,
        customersVersion: now,
        salesCount: loadSales().length,
      );
    }

    return syncedCount;
  }

  // ── دەستپێکردن و هاوکاتکردنی داتاکان لەگەڵ فایەربەیس ─────────────────────
  Future<void> initialize() async {
    try {
      final bool hasLocalData =
          loadUsers().isNotEmpty && loadProducts().isNotEmpty;

      final Map<String, dynamic>? remoteSync =
          await _firestore.getDocument(_syncCollection, _syncDoc);

      if (remoteSync == null) {
        if (!hasLocalData) {
          final List<Map<String, dynamic>> remoteUsers =
              await _firestore.getCollection('users');
          final List<Map<String, dynamic>> remoteProds =
              await _firestore.getCollection('products');

          if (remoteUsers.isEmpty && remoteProds.isEmpty) {
            await _seedToFirestore();
          } else {
            await _fullFetchFromFirestore();
          }
        }
        return;
      }

      isOnlineNotifier.value = true;

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
      final String localCustVer = _storage.readString(_keyCustomersVer) ?? '';
      final String remoteCustVer =
          remoteSync['customersVersion']?.toString() ?? '';
      final int localSalesCount = _storage.readInt(_keySalesCount);
      final int remoteSalesCount =
          (remoteSync['salesCount'] as num?)?.toInt() ?? 0;

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
          localCustVer != remoteCustVer ||
          loadCustomers().isEmpty) {
        final List<Map<String, dynamic>> custs =
            await _firestore.getCollection('customers');
        if (custs.isNotEmpty) {
          final List<Customer> list =
              custs.map(Customer.fromJson).toList(growable: false);
          await _storage.writeList(
            LocalStorage.customersKey,
            list.map((Customer c) => c.toJson()).toList(),
          );
          await _storage.writeString(_keyCustomersVer, remoteCustVer);
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

      // ئەگەر داتای ئۆفلاین لە پێشتر مابێت، یەکسەر دەینێرێت
      if (pendingSyncCountNotifier.value > 0) {
        await syncPendingQueue();
      }
    } catch (e) {
      debugPrint('PosRepository.initialize offline mode active: $e');
      isOnlineNotifier.value = false;
    }
  }

  Future<void> _fullFetchFromFirestore() async {
    try {
      final List<Map<String, dynamic>> cats =
          await _firestore.getCollection('categories');
      final List<Map<String, dynamic>> prods =
          await _firestore.getCollection('products');
      final List<Map<String, dynamic>> sales =
          await _firestore.getCollection('sales');
      final List<Map<String, dynamic>> users =
          await _firestore.getCollection('users');
      final List<Map<String, dynamic>> customers =
          await _firestore.getCollection('customers');
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
      if (customers.isNotEmpty) {
        final List<Customer> list =
            customers.map(Customer.fromJson).toList(growable: false);
        await _storage.writeList(
            LocalStorage.customersKey, list.map((c) => c.toJson()).toList());
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
        customersVersion: now,
        salesCount: sales.length,
      );
      await _storage.writeBool(LocalStorage.seededKey, true);
      isOnlineNotifier.value = true;
    } catch (e) {
      debugPrint('PosRepository._fullFetchFromFirestore error: $e');
      isOnlineNotifier.value = false;
    }
  }

  // ── کاڵاکان ─────────────────────────────────────────────────────────────
  List<Product> loadProducts() => _storage
      .readList(LocalStorage.productsKey)
      .map(Product.fromJson)
      .toList(growable: false);

  Future<void> saveSingleProduct(Product product) async {
    final List<Product> prods = loadProducts();
    final int index = prods.indexWhere((Product p) => p.id == product.id);
    final List<Product> updated = List<Product>.from(prods);
    if (index < 0) {
      updated.add(product);
    } else {
      updated[index] = product;
    }
    // هەردەم لۆکاڵ سەرەتا نوێ دەبێتەوە
    await _storage.writeList(
      LocalStorage.productsKey,
      updated.map((Product p) => p.toJson()).toList(),
    );

    try {
      final bool ok = await _firestore.setDocument(
          'products', product.id, product.toJson());
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyProductsVer, ver);
        _touchSyncMetadata(productsVersion: ver);
      } else {
        _enqueueOfflineAction(
            action: 'set',
            collection: 'products',
            documentId: product.id,
            data: product.toJson());
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'set',
          collection: 'products',
          documentId: product.id,
          data: product.toJson());
    }
  }

  Future<void> deleteSingleProduct(String id) async {
    final List<Product> prods = loadProducts();
    final List<Product> updated =
        prods.where((Product p) => p.id != id).toList();
    await _storage.writeList(
      LocalStorage.productsKey,
      updated.map((Product p) => p.toJson()).toList(),
    );

    try {
      final bool ok = await _firestore.deleteDocument('products', id);
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyProductsVer, ver);
        _touchSyncMetadata(productsVersion: ver);
      } else {
        _enqueueOfflineAction(
            action: 'delete', collection: 'products', documentId: id);
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'delete', collection: 'products', documentId: id);
    }
  }

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

    for (final Product p in changedProds) {
      try {
        final bool ok =
            await _firestore.setDocument('products', p.id, p.toJson());
        if (!ok) {
          _enqueueOfflineAction(
              action: 'set',
              collection: 'products',
              documentId: p.id,
              data: p.toJson());
        }
      } catch (_) {
        _enqueueOfflineAction(
            action: 'set',
            collection: 'products',
            documentId: p.id,
            data: p.toJson());
      }
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

    for (final String id in deletedIds) {
      deleteSingleProduct(id);
    }
    for (final Product p in products) {
      saveSingleProduct(p);
    }
  }

  // ── پۆلەکان ─────────────────────────────────────────────────────────────
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
      final bool ok = await _firestore.setDocument(
          'categories', category.id, category.toJson());
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyCategoriesVer, ver);
        _touchSyncMetadata(categoriesVersion: ver);
      } else {
        _enqueueOfflineAction(
            action: 'set',
            collection: 'categories',
            documentId: category.id,
            data: category.toJson());
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'set',
          collection: 'categories',
          documentId: category.id,
          data: category.toJson());
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
      final bool ok = await _firestore.deleteDocument('categories', id);
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyCategoriesVer, ver);
        _touchSyncMetadata(categoriesVersion: ver);
      } else {
        _enqueueOfflineAction(
            action: 'delete', collection: 'categories', documentId: id);
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'delete', collection: 'categories', documentId: id);
    }
  }

  Future<void> saveCategories(List<Category> categories) async {
    await _storage.writeList(
      LocalStorage.categoriesKey,
      categories.map((Category category) => category.toJson()).toList(),
    );
    for (final Category c in categories) {
      saveSingleCategory(c);
    }
  }

  // ── پسووڵەکان (کارکردنی ١٠٠٪ تەواوی فرۆشتن لە ئۆفلاین) ─────────────────────
  List<Sale> loadSales() => _storage
      .readList(LocalStorage.salesKey)
      .map(Sale.fromJson)
      .toList(growable: false);

  /// پاشەکەوتکردنی ١ پسووڵە — دەستبەجێ چاپ دەکرێت و تەواو دەبێت لە ئۆفلاین
  Future<void> saveSingleSale(Sale sale) async {
    final List<Sale> sales = loadSales();
    final int index = sales.indexWhere((Sale s) => s.id == sale.id);
    final List<Sale> updated = List<Sale>.from(sales);
    if (index < 0) {
      updated.insert(0, sale);
    } else {
      updated[index] = sale;
    }
    // هەردەم لە مەمۆری و لۆکاڵ دەستبەجێ پاشەکەوت دەبێت (سفر چرکە چاوەڕوانی بۆ کاشێر)
    await _storage.writeList(
      LocalStorage.salesKey,
      updated.map((Sale s) => s.toJson()).toList(),
    );

    try {
      final bool ok =
          await _firestore.setDocument('sales', sale.id, sale.toJson());
      if (ok) {
        isOnlineNotifier.value = true;
        final int count = updated.length;
        await _storage.writeInt(_keySalesCount, count);
        _touchSyncMetadata(salesCount: count);
      } else {
        _enqueueOfflineAction(
            action: 'set',
            collection: 'sales',
            documentId: sale.id,
            data: sale.toJson());
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'set',
          collection: 'sales',
          documentId: sale.id,
          data: sale.toJson());
    }
  }

  Future<void> saveSales(List<Sale> sales) async {
    await _storage.writeList(
      LocalStorage.salesKey,
      sales.map((Sale sale) => sale.toJson()).toList(),
    );
    for (final Sale s in sales) {
      saveSingleSale(s);
    }
  }

  // ── بەکارهێنەران ────────────────────────────────────────────────────────
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
      final bool ok =
          await _firestore.setDocument('users', user.id, user.toJson());
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyUsersVer, ver);
        _touchSyncMetadata(usersVersion: ver);
      } else {
        _enqueueOfflineAction(
            action: 'set',
            collection: 'users',
            documentId: user.id,
            data: user.toJson());
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'set',
          collection: 'users',
          documentId: user.id,
          data: user.toJson());
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
      final bool ok = await _firestore.deleteDocument('users', id);
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyUsersVer, ver);
        _touchSyncMetadata(usersVersion: ver);
      } else {
        _enqueueOfflineAction(
            action: 'delete', collection: 'users', documentId: id);
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'delete', collection: 'users', documentId: id);
    }
  }

  Future<void> saveUsers(List<AppUser> users) async {
    await _storage.writeList(
      LocalStorage.usersKey,
      users.map((AppUser user) => user.toJson()).toList(),
    );
    for (final AppUser u in users) {
      saveSingleUser(u);
    }
  }

  // ── کڕیاران و پۆینتەکان ──────────────────────────────────────────────────
  List<Customer> loadCustomers() => _storage
      .readList(LocalStorage.customersKey)
      .map(Customer.fromJson)
      .toList(growable: false);

  Future<void> saveSingleCustomer(Customer customer) async {
    final List<Customer> custs = loadCustomers();
    final int index = custs.indexWhere((Customer c) => c.id == customer.id);
    final List<Customer> updated = List<Customer>.from(custs);
    if (index < 0) {
      updated.add(customer);
    } else {
      updated[index] = customer;
    }
    await _storage.writeList(
      LocalStorage.customersKey,
      updated.map((Customer c) => c.toJson()).toList(),
    );

    try {
      final bool ok = await _firestore.setDocument(
          'customers', customer.id, customer.toJson());
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyCustomersVer, ver);
        _touchSyncMetadata(customersVersion: ver);
      } else {
        _enqueueOfflineAction(
          action: 'set',
          collection: 'customers',
          documentId: customer.id,
          data: customer.toJson(),
        );
      }
    } catch (_) {
      _enqueueOfflineAction(
        action: 'set',
        collection: 'customers',
        documentId: customer.id,
        data: customer.toJson(),
      );
    }
  }

  Future<void> deleteSingleCustomer(String id) async {
    final List<Customer> custs = loadCustomers();
    final List<Customer> updated =
        custs.where((Customer c) => c.id != id).toList();
    await _storage.writeList(
      LocalStorage.customersKey,
      updated.map((Customer c) => c.toJson()).toList(),
    );

    try {
      final bool ok = await _firestore.deleteDocument('customers', id);
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keyCustomersVer, ver);
        _touchSyncMetadata(customersVersion: ver);
      } else {
        _enqueueOfflineAction(
          action: 'delete',
          collection: 'customers',
          documentId: id,
        );
      }
    } catch (_) {
      _enqueueOfflineAction(
        action: 'delete',
        collection: 'customers',
        documentId: id,
      );
    }
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    await _storage.writeList(
      LocalStorage.customersKey,
      customers.map((Customer customer) => customer.toJson()).toList(),
    );
    for (final Customer c in customers) {
      saveSingleCustomer(c);
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
      final bool ok = await _firestore.setDocument(
          'settings', 'store', settings.toJson());
      if (ok) {
        isOnlineNotifier.value = true;
        final String ver = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.writeString(_keySettingsVer, ver);
        _touchSyncMetadata(settingsVersion: ver);
      } else {
        _enqueueOfflineAction(
            action: 'set',
            collection: 'settings',
            documentId: 'store',
            data: settings.toJson());
      }
    } catch (_) {
      _enqueueOfflineAction(
          action: 'set',
          collection: 'settings',
          documentId: 'store',
          data: settings.toJson());
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
    } catch (_) {
      _enqueueOfflineAction(
        action: 'set',
        collection: 'sequences',
        documentId: 'invoices',
        data: <String, dynamic>{
          'counter': next,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
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
    } catch (_) {
      _enqueueOfflineAction(
        action: 'set',
        collection: 'sequences',
        documentId: 'invoices',
        data: <String, dynamic>{
          'counter': value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
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
    final List<Customer> customers = loadCustomers();

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
      for (final Customer cust in customers) {
        _firestore.deleteDocument('customers', cust.id);
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
      customersVersion: now,
      salesCount: sales.length,
    );
    await markSeeded();
  }

  Future<void> _touchSyncMetadata({
    String? productsVersion,
    String? categoriesVersion,
    String? usersVersion,
    String? settingsVersion,
    String? customersVersion,
    int? salesCount,
  }) async {
    try {
      final Map<String, dynamic> update = <String, dynamic>{};
      if (productsVersion != null) update['productsVersion'] = productsVersion;
      if (categoriesVersion != null) update['categoriesVersion'] = categoriesVersion;
      if (usersVersion != null) update['usersVersion'] = usersVersion;
      if (settingsVersion != null) update['settingsVersion'] = settingsVersion;
      if (customersVersion != null) update['customersVersion'] = customersVersion;
      if (salesCount != null) update['salesCount'] = salesCount;
      update['lastSyncAt'] = DateTime.now().toIso8601String();

      _firestore.setDocument(_syncCollection, _syncDoc, update);
    } catch (e) {
      debugPrint('PosRepository._touchSyncMetadata error: $e');
    }
  }
}