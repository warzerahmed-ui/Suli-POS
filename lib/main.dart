import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_providers.dart';

/// خاڵی دەستپێکی سیستەمەکە.
/// English: opens the local storage, seeds demo data on first run, then starts
/// the UI with every controller provided through `provider`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppProviders providers = await AppProviders.bootstrap();
  runApp(PosApp(providers: providers));
}
