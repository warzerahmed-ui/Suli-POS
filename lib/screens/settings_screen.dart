import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../models/store_settings.dart';
import '../state/app_providers.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/brand_badge.dart';

/// شاشەی ڕێکخستنەکان: زانیاری فرۆشگا، دراو، باج، ڕووکار و بەڕێوەبردنی داتا.
/// English: store profile, money/tax preferences, appearance and data tools.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();

  int _decimals = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _syncFromSettings();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currencyController.dispose();
    _taxController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _syncFromSettings() {
    final StoreSettings settings = context.read<SettingsController>().settings;
    _storeNameController.text = settings.storeName;
    _phoneController.text = settings.phone;
    _addressController.text = settings.address;
    _currencyController.text = settings.currencySymbol;
    _taxController.text = settings.taxPercent == 0
        ? '0'
        : settings.taxPercent.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    _footerController.text = settings.receiptFooter;
    _decimals = settings.currencyDecimals;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final SettingsController controller = context.read<SettingsController>();
    await controller.save(
      controller.settings.copyWith(
        storeName: _storeNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        currencySymbol: _currencyController.text.trim(),
        currencyDecimals: _decimals,
        taxPercent:
            double.tryParse(_taxController.text.trim().replaceAll(',', '')) ?? 0,
        receiptFooter: _footerController.text.trim(),
      ),
    );
    if (!mounted) return;
    AppDialogs.showMessage(context, AppStrings.settingsSaved);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Form(
          key: _formKey,
          child: SectionCard(
            title: AppStrings.storeInfo,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.storeName,
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                          ? AppStrings.required
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.phone} (${AppStrings.optional})',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.address} (${AppStrings.optional})',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _currencyController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.currencySymbol,
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (String? value) =>
                            (value == null || value.trim().isEmpty)
                                ? AppStrings.required
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _decimals,
                        decoration: const InputDecoration(
                          labelText: AppStrings.currencyDecimals,
                          prefixIcon: Icon(Icons.numbers_outlined),
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem<int>(value: 0, child: Text('0')),
                          DropdownMenuItem<int>(value: 1, child: Text('1')),
                          DropdownMenuItem<int>(value: 2, child: Text('2')),
                        ],
                        onChanged: (int? value) =>
                            setState(() => _decimals = value ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.taxPercent,
                    prefixIcon: Icon(Icons.percent),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _footerController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: AppStrings.receiptFooter,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(AppStrings.save),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: AppStrings.appearance,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: <Widget>[
              SwitchListTile(
                value: settings.isDarkMode,
                onChanged: settings.setDarkMode,
                secondary: Icon(
                  settings.isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                title: const Text(AppStrings.darkMode),
              ),
              const ListTile(
                leading: Icon(Icons.translate),
                title: Text(AppStrings.language),
                subtitle: Text(AppStrings.kurdish),
                trailing: Icon(Icons.lock_outline, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: AppStrings.dataManagement,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text(AppStrings.seedDemoData),
                subtitle: const Text(AppStrings.seedConfirm),
                trailing: const Icon(Icons.chevron_left),
                onTap: _loadDemoData,
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  AppStrings.resetData,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text(AppStrings.resetConfirm),
                trailing: const Icon(Icons.chevron_left),
                onTap: _resetData,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: AppStrings.about,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const RandSuiteLogo(isCompact: true, size: 28),
              const SizedBox(height: 10),
              Text(
                '${AppStrings.appTitle} — ${AppStrings.version} 1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.developedBy,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.storageNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بارکردنەوەی داتای نموونە.
  Future<void> _loadDemoData() async {
    final bool confirmed = await AppDialogs.confirm(
      context,
      message: AppStrings.seedConfirm,
      confirmLabel: AppStrings.seedDemoData,
      danger: true,
    );
    if (!confirmed || !mounted) return;

    await context.read<AppProviders>().loadDemoData();
    if (!mounted) return;
    _syncFromSettings();
    setState(() {});
    AppDialogs.showMessage(context, AppStrings.seedDone);
  }

  /// سڕینەوەی هەموو داتا (بەکارهێنەر دەچێتە دەرەوە).
  Future<void> _resetData() async {
    final bool confirmed = await AppDialogs.confirm(
      context,
      message: AppStrings.resetConfirm,
      confirmLabel: AppStrings.resetData,
      danger: true,
    );
    if (!confirmed || !mounted) return;

    await context.read<AppProviders>().resetAll();
    if (!mounted) return;
    AppDialogs.showMessage(context, AppStrings.resetDone);
  }
}
