import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_controller.dart';

/// ئاسانکارییەکان بۆ `BuildContext`.
///
/// English: shortcuts used inside `build()` methods. They call `watch`, so a
/// widget that shows money automatically rebuilds when settings change.
extension AppContextExtensions on BuildContext {
  SettingsController get appSettings => watch<SettingsController>();

  /// شێوەکردنی بڕی پارە بەپێی دراوی دیاریکراو لە ڕێکخستنەکان.
  String money(num value) => watch<SettingsController>().money(value);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
