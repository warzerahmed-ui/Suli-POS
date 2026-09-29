import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../models/app_user.dart';
import '../state/auth_controller.dart';
import '../state/cart_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import 'dashboard_screen.dart';
import 'pos/pos_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

/// بەشێکی چوارچێوەکە (مێنوو + شاشە).
class _ShellSection {
  const _ShellSection({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// چوارچێوەی سەرەکی سیستەم: شریتی سەرەوە + مێنووی لاتەنیشت (یان درێوەر).
/// English: the main shell. A rail is used on wide screens, a drawer on
/// phones/tablets. Cashiers only see the sections they are allowed to use.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<_ShellSection> _sectionsFor(bool isAdmin) {
    return <_ShellSection>[
      _ShellSection(
        label: AppStrings.dashboard,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        builder: (BuildContext context) => const DashboardScreen(),
      ),
      _ShellSection(
        label: AppStrings.pos,
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        builder: (BuildContext context) => const PosScreen(),
      ),
      _ShellSection(
        label: AppStrings.sales,
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        builder: (BuildContext context) => const SalesScreen(),
      ),
      if (isAdmin) ...<_ShellSection>[
        _ShellSection(
          label: AppStrings.products,
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          builder: (BuildContext context) => const ProductsScreen(),
        ),
        _ShellSection(
          label: AppStrings.reports,
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
          builder: (BuildContext context) => const ReportsScreen(),
        ),
        _ShellSection(
          label: AppStrings.users,
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          builder: (BuildContext context) => const UsersScreen(),
        ),
        _ShellSection(
          label: AppStrings.settings,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          builder: (BuildContext context) => const SettingsScreen(),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthController auth = context.watch<AuthController>();
    final SettingsController settings = context.watch<SettingsController>();
    final List<_ShellSection> sections = _sectionsFor(auth.isAdmin);
    final int index = _index >= sections.length ? 0 : _index;
    final bool wide = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              settings.settings.storeName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              sections[index].label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: AppStrings.darkMode,
            onPressed: settings.toggleDarkMode,
            icon: Icon(
              settings.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const _UserMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : _buildDrawer(context, sections, index),
      body: Row(
        children: <Widget>[
          if (wide)
            NavigationRail(
              selectedIndex: index,
              extended: MediaQuery.sizeOf(context).width >= 1320,
              labelType: MediaQuery.sizeOf(context).width >= 1320
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              onDestinationSelected: (int value) =>
                  setState(() => _index = value),
              destinations: sections
                  .map(
                    (_ShellSection section) => NavigationRailDestination(
                      icon: Icon(section.icon),
                      selectedIcon: Icon(section.selectedIcon),
                      label: Text(section.label),
                    ),
                  )
                  .toList(),
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: index,
              children: sections
                  .map((_ShellSection section) => section.builder(context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    List<_ShellSection> sections,
    int index,
  ) {
    final SettingsController settings = context.watch<SettingsController>();
    return NavigationDrawer(
      selectedIndex: index,
      onDestinationSelected: (int value) {
        Navigator.of(context).pop();
        setState(() => _index = value);
      },
      children: <Widget>[
        DrawerHeader(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.storefront_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                settings.settings.storeName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        ...sections.map(
          (_ShellSection section) => NavigationDrawerDestination(
            icon: Icon(section.icon),
            selectedIcon: Icon(section.selectedIcon),
            label: Text(section.label),
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(
            settings.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          title: const Text(AppStrings.darkMode),
          onTap: settings.toggleDarkMode,
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text(AppStrings.logout),
          onTap: () {
            Navigator.of(context).pop();
            confirmSignOut(context);
          },
        ),
      ],
    );
  }
}

/// پشتڕاستکردنەوەی دەرچوون و پاککردنەوەی سەبەتە.
Future<void> confirmSignOut(BuildContext context) async {
  final bool confirmed = await AppDialogs.confirm(
    context,
    message: AppStrings.confirmLogout,
    confirmLabel: AppStrings.logout,
    danger: true,
  );
  if (!confirmed || !context.mounted) return;
  context.read<CartController>().resetAfterSale();
  context.read<AuthController>().signOut();
}

/// لیستی بەکارهێنەر لە شریتی سەرەوە (زانیاری + دەرچوون).
class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton();

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final AppUser? user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: user.fullName,
      onSelected: (String value) {
        if (value == 'logout') confirmSignOut(context);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(user.role.label),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: <Widget>[
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text(AppStrings.logout),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              child: Text(user.initials, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Text(user.fullName),
          ],
        ),
      ),
    );
  }
}
