import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage(this._preferences);

  final SharedPreferences _preferences;

  static const String productsKey = 'pos.products';
  static const String categoriesKey = 'pos.categories';
  static const String salesKey = 'pos.sales';
  static const String usersKey = 'pos.users';
  static const String settingsKey = 'pos.settings';
  static const String customersKey = 'pos.customers';
  static const String expensesKey = 'pos.expenses';
  static const String heldCartsKey = 'pos.heldCarts';
  static const String invoiceCounterKey = 'pos.invoiceCounter';
  static const String seededKey = 'pos.seeded';
  static const String currentShiftKey = 'pos.currentShift';
  static const String shiftsHistoryKey = 'pos.shiftsHistory';

  static Future<LocalStorage> open() async => LocalStorage(await SharedPreferences.getInstance());

  List<Map<String, dynamic>> readList(String key) {
    final String? str = _preferences.getString(key);
    if (str == null || str.isEmpty) return <Map<String, dynamic>>[];
    try {
      final List<dynamic> decoded = jsonDecode(str) as List<dynamic>;
      return decoded.map((dynamic e) => e as Map<String, dynamic>).toList(growable: false);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? readMap(String key) {
    final String? str = _preferences.getString(key);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  String? readString(String key) => _preferences.getString(key);
  Future<void> writeString(String key, String value) async => _preferences.setString(key, value);

  bool readBool(String key, {bool defaultValue = false}) => _preferences.getBool(key) ?? defaultValue;
  Future<void> writeBool(String key, bool value) async => _preferences.setBool(key, value);

  int readInt(String key, {int defaultValue = 0}) => _preferences.getInt(key) ?? defaultValue;
  Future<void> writeInt(String key, int value) async => _preferences.setInt(key, value);
  
  Future<void> remove(String key) async => _preferences.remove(key);

  Future<void> clearAll() async => _preferences.clear();

  String exportBackup() {
    final Map<String, dynamic> allData = <String, dynamic>{};
    for (final String key in _preferences.getKeys()) {
      final Object? value = _preferences.get(key);
      allData[key] = value;
    }
    return jsonEncode(allData);
  }

  Future<void> importBackup(String jsonString) async {
    final Map<String, dynamic> allData = jsonDecode(jsonString) as Map<String, dynamic>;
    await _preferences.clear();
    for (final MapEntry<String, dynamic> entry in allData.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;
      if (value is String) {
        await _preferences.setString(key, value);
      } else if (value is int) {
        await _preferences.setInt(key, value);
      } else if (value is double) {
        await _preferences.setDouble(key, value);
      } else if (value is bool) {
        await _preferences.setBool(key, value);
      } else if (value is List<String>) {
        await _preferences.setStringList(key, value);
      }
    }
  }
}
