import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../data/pos_repository.dart';
import '../models/store_settings.dart';

/// کۆنترۆڵەری ڕێکخستنەکانی فرۆشگا (ناو، دراو، باج، دۆخی تاریک).
///
/// English: holds the store settings and exposes money formatting so every
/// screen shows the same currency symbol / decimals.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final PosRepository _repository;

  StoreSettings _settings = const StoreSettings();

  StoreSettings get settings => _settings;

  bool get isDarkMode => _settings.isDarkMode;

  String get currencySymbol => _settings.currencySymbol;

  void load() {
    _settings = _repository.loadSettings();
    notifyListeners();
  }

  Future<void> save(StoreSettings value) async {
    _settings = value;
    await _repository.saveSettings(value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) =>
      save(_settings.copyWith(isDarkMode: value));

  Future<void> toggleDarkMode() => setDarkMode(!_settings.isDarkMode);

  /// شێوەکردنی بڕی پارە بەپێی ڕێکخستنەکان.
  String money(num value) => Formatters.money(
        value,
        symbol: _settings.currencySymbol,
        decimals: _settings.currencyDecimals,
      );
}
