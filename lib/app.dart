import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_strings.dart';
import 'core/app_theme.dart';
import 'data/pos_repository.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_providers.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'state/customer_controller.dart';
import 'state/expenses_controller.dart';
import 'state/inventory_controller.dart';
import 'state/sales_controller.dart';
import 'state/settings_controller.dart';

/// ڕەگی ڕووکار — کۆنترۆڵەرەکان بەردەست دەخات بۆ هەموو شاشەکان.
/// English: provides every controller to the widget tree via `provider`.
class PosApp extends StatelessWidget {
  const PosApp({super.key, required this.providers});

  final AppProviders providers;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PosRepository>.value(value: providers.repository),
        ChangeNotifierProvider<SettingsController>.value(
          value: providers.settings,
        ),
        ChangeNotifierProvider<AuthController>.value(value: providers.auth),
        ChangeNotifierProvider<InventoryController>.value(
          value: providers.inventory,
        ),
        ChangeNotifierProvider<CartController>.value(value: providers.cart),
        ChangeNotifierProvider<SalesController>.value(value: providers.sales),
        ChangeNotifierProvider<CustomerController>.value(
          value: providers.customer,
        ),
        ChangeNotifierProvider<ExpensesController>.value(
          value: providers.expenses,
        ),
        Provider<AppProviders>.value(value: providers),
      ],
      child: const PosMaterialApp(),
    );
  }
}

/// ڕێکخستنی `MaterialApp` (ڕووکار، ڕەنگ، ئاراستەی RTL).
class PosMaterialApp extends StatelessWidget {
  const PosMaterialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<SettingsController>().isDarkMode;
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      // ڕووکارەکە کوردییە (RTL) — زمانی `ckb` لە Flutter پشتگیری نەکراوە، بۆیە
      // ئاراستەکە بە دەست دیاری دەکەین.
      builder: (BuildContext context, Widget? child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RootScreen(),
    );
  }
}

/// هەڵبژاردنی ڕووکار: شاشەی چوونەژوورەوە یان سیستەمی سەرەکی.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    return auth.isLoggedIn ? const AppShell() : const LoginScreen();
  }
}
