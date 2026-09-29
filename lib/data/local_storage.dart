import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// پاشەکەوتکردنی ناوخۆیی داتا بە شێوەی JSON لە `SharedPreferences`.
///
/// English: tiny persistence layer. Everything the app needs fits in a handful
/// of lists, so JSON-in-SharedPreferences keeps the app dependency-light and
/// working on Windows, Android and the web. Swap this class for a real database
/// (sqlite/postgres API) without touching the rest of the app.
class LocalStorage {
  LocalStorage(this._preferences);

  final SharedPreferences _preferences;

  static const String productsKey = 'pos.products';
  static const String categoriesKey = 'pos.categories';
  static const String salesKey = 'pos.sales';
  static const String usersKey = 'pos.users';
  static const String settingsKey = 'pos.settings';
  static const String heldCartsKey = 'pos.heldCarts';
  static const String invoiceCounterKey = 'pos.invoiceCounter';
  static const String seededKey = 'pos.seeded';

  /// کردنەوەی هەڵگرتن.
  static Future<LocalStorage> open() async =>
      LocalStorage(await SharedPreferences.getInstance());

  List<Map<String, dynamic>> readList(String key) {
    final String? raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> item) =>
              Map<String, dynamic>.from(item))
          .toList();
    } on FormatException {
      // داتای تێکچوو — وەک بەتاڵ مامەڵەی لەگەڵ دەکرێت.
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) =>
      _preferences.setString(key, jsonEncode(items));

  Map<String, dynamic>? readMap(String key) {
    final String? raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<dynamic, dynamic>) return null;
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) =>
      _preferences.setString(key, jsonEncode(value));

  String? readString(String key) => _preferences.getString(key);

  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);

  int readInt(String key, {int fallback = 0}) =>
      _preferences.getInt(key) ?? fallback;

  Future<void> writeInt(String key, int value) =>
      _preferences.setInt(key, value);

  bool readBool(String key, {bool fallback = false}) =>
      _preferences.getBool(key) ?? fallback;

  Future<void> writeBool(String key, bool value) =>
      _preferences.setBool(key, value);

  Future<void> remove(String key) => _preferences.remove(key);

  Future<void> clearAll() => _preferences.clear();
}
