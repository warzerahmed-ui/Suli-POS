import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/app_user.dart';
import '../state/auth_controller.dart';
import '../state/cart_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';
import '../data/pos_repository.dart';
import '../widgets/brand_badge.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'pos/pos_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

/// Ø¨Û•Ø´ÛŽÚ©ÛŒ Ú†ÙˆØ§Ø±Ú†ÛŽÙˆÛ•Ú©Û• (Ù…ÛŽÙ†ÙˆÙˆ + Ø´Ø§Ø´Û•).
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

/// Ú†ÙˆØ§Ø±Ú†ÛŽÙˆÛ•ÛŒ Ø³Û•Ø±Û•Ú©ÛŒ Ø³ÛŒØ³ØªÛ•Ù…: Ø´Ø±ÛŒØªÛŒ Ø³Û•Ø±Û•ÙˆÛ• + Ù…ÛŽÙ†ÙˆÙˆÛŒ Ù„Ø§ØªÛ•Ù†ÛŒØ´Øª (ÛŒØ§Ù† Ø¯Ø±ÛŽÙˆÛ•Ø±).
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
      _ShellSection(
        label: 'کڕیاران و پۆینت',
        icon: Icons.stars_outlined,
        selectedIcon: Icons.stars,
        builder: (BuildContext context) => const CustomersScreen(),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!wide) ...<Widget>[
              const RandSuiteLogo(isCompact: true, size: 24),
              const SizedBox(width: 12),
            ],
            Column(
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
          ],
        ),
        actions: <Widget>[
          const _ConnectionBadge(),
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
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: RandSuiteLogo(isCompact: true, size: 28),
              ),
              trailing: const Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: PoweredByRandSuite(),
                  ),
                ),
              ),
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
              const RandSuiteLogo(isCompact: true, size: 32),
              const SizedBox(height: 12),
              Text(
                settings.settings.storeName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
          leading: const Icon(
            Icons.install_mobile_rounded,
            color: AppColors.primary,
          ),
          title: const Text(AppStrings.installApp),
          subtitle: const Text(
            AppStrings.installAppDesc,
            style: TextStyle(fontSize: 11),
          ),
          onTap: () {
            Navigator.of(context).pop();
            _showPwaInstallGuide(context);
          },
        ),
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

/// Ù¾Ø´ØªÚ•Ø§Ø³ØªÚ©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø¯Û•Ø±Ú†ÙˆÙˆÙ† Ùˆ Ù¾Ø§Ú©Ú©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø³Û•Ø¨Û•ØªÛ•.
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

/// Ù„ÛŒØ³ØªÛŒ Ø¨Û•Ú©Ø§Ø±Ù‡ÛŽÙ†Û•Ø± Ù„Û• Ø´Ø±ÛŒØªÛŒ Ø³Û•Ø±Û•ÙˆÛ• (Ø²Ø§Ù†ÛŒØ§Ø±ÛŒ + Ø¯Û•Ø±Ú†ÙˆÙˆÙ†).
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

/// نیشاندەری زیرەکی پەیوەندی و ئۆفلاین لە شریتی سەرەوە
class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge();

  @override
  Widget build(BuildContext context) {
    final PosRepository repo = context.watch<PosRepository>();

    return ValueListenableBuilder<bool>(
      valueListenable: repo.isOnlineNotifier,
      builder: (BuildContext context, bool isOnline, Widget? _) {
        return ValueListenableBuilder<int>(
          valueListenable: repo.pendingSyncCountNotifier,
          builder: (BuildContext context, int pending, Widget? _) {
            final bool fullyOnline = isOnline && pending == 0;
            final Color color = fullyOnline
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B);
            final IconData icon = fullyOnline
                ? Icons.cloud_done_rounded
                : (pending > 0
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_off_rounded);
            final String label = fullyOnline
                ? 'ئۆنلاین (فایەربەیس)'
                : (pending > 0
                      ? 'ئۆفلاین ($pending چاوەڕێیە)'
                      : 'ئۆفلاین (بێ ئینتەرنێت)');

            return Tooltip(
              message: fullyOnline
                  ? 'سیستەم پەیوەستە بە فایەربەیس (suli-pos) - هەموو داتاکان هاوکاتن'
                  : 'سیستەم لە دۆخی ئۆفلایندایە - کارکردن بەردەوامە و هیچ فرۆشتنێک ناوەستێت. کلیک بکە بۆ هاوکاتکردنەوە.',
              child: InkWell(
                onTap: () =>
                    _showSyncDialog(context, repo, fullyOnline, pending),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSyncDialog(
    BuildContext context,
    PosRepository repo,
    bool isOnline,
    int pending,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        bool syncing = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: <Widget>[
                  Icon(
                    isOnline
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  const Text('دۆخی هاوکاتکردنی فایەربەیس'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isOnline
                        ? 'سیستەم بە سەرکەوتوویی پەیوەستە بە هەوری فایەربەیس (suli-pos).'
                        : 'سیستەمی مارکێتەکەت لە دۆخی ئۆفلاین کار دەکات. هەموو فرۆشتنەکان لە بیرگەی ئامێرەکەدا بە تەواوی پارێزراون و بە هیچ جۆرێک کار ناوەستێت.',
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text('مامەڵەی چاوەڕێکراو بۆ ناردن:'),
                        Text(
                          '$pending دانە',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: pending > 0
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('داخستن'),
                ),
                FilledButton.icon(
                  onPressed: syncing
                      ? null
                      : () async {
                          setState(() => syncing = true);
                          final int synced = await repo.syncPendingQueue();
                          setState(() => syncing = false);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  synced > 0
                                      ? '$synced مامەڵە بە سەرکەوتوویی نێردرانە فایەربەیس.'
                                      : (repo.isOnlineNotifier.value
                                            ? 'پەیوەندی لەسەر هێڵە و هەموو داتاکان هاوکاتن.'
                                            : 'هێشتا ئینتەرنێت پەیدا نەبووەتەوە، داتاکان لە ئامێرەکە پارێزراون.'),
                                ),
                              ),
                            );
                          }
                        },
                  icon: syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(
                    syncing ? 'هاوکات دەکرێت...' : 'هاوکاتکردنەوە ئێستا',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

void _showPwaInstallGuide(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      return DefaultTabController(
        length: 2,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.install_mobile_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  AppStrings.pwaInstallTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const TabBar(
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  tabs: <Widget>[
                    Tab(icon: Icon(Icons.apple), text: 'iPhone / iPad'),
                    Tab(icon: Icon(Icons.android), text: 'Android'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: TabBarView(
                    children: <Widget>[
                      SingleChildScrollView(
                        child: Text(
                          AppStrings.pwaInstallIosGuide,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Text(
                          AppStrings.pwaInstallAndroidGuide,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.close),
            ),
          ],
        ),
      );
    },
  );
}
