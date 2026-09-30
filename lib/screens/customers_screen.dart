import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../models/customer.dart';
import '../state/customer_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/app_widgets.dart';

/// شاشەی بەڕێوەبردنی کڕیاران و سیستەمی پۆینتی وەفاداری (Loyalty Points).
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CustomerController controller = context.watch<CustomerController>();
    final SettingsController settings = context.watch<SettingsController>();

    final List<Customer> customers = controller.search(_query);
    final int totalPoints = controller.totalActivePoints;
    final double pointsWorth = totalPoints * settings.settings.amountPerPoint;

    return Column(
      children: <Widget>[
        // بەشی سەرەوە: کورتەی ئامارەکان
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isCompact = constraints.maxWidth < 600;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _MetricCard(
                    title: 'کۆی کڕیاران',
                    value: Formatters.number(controller.customerCount),
                    icon: Icons.people_outline,
                    color: theme.colorScheme.primary,
                    width: isCompact ? (constraints.maxWidth - 12) / 2 : 180,
                  ),
                  _MetricCard(
                    title: 'کۆی پۆینتی چالاک',
                    value: '${Formatters.number(totalPoints)} ⭐',
                    icon: Icons.stars,
                    color: Colors.amber.shade700,
                    width: isCompact ? (constraints.maxWidth - 12) / 2 : 180,
                  ),
                  _MetricCard(
                    title: 'بەهای پۆینتەکان',
                    value: settings.money(pointsWorth),
                    icon: Icons.monetization_on_outlined,
                    color: Colors.green.shade700,
                    width: isCompact ? constraints.maxWidth : 210,
                  ),
                ],
              );
            },
          ),
        ),

        // خانەی گەڕان و دوگمەی زیادکردنی کڕیار
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'گەڕان بەپێی ناو یان ژمارە مۆبایل...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (String val) => setState(() => _query = val),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => openCustomerForm(context),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('کڕیاری نوێ'),
              ),
            ],
          ),
        ),

        // لیستی کڕیاران
        Expanded(
          child: customers.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline,
                  title: _query.isEmpty
                      ? 'هیچ کڕیارێک تۆمار نەکراوە'
                      : 'هیچ کڕیارێک بەپێی ئەم ناوە نەدۆزرایەوە',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) =>
                      _CustomerTile(customer: customers[index]),
                ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();
    final CustomerController controller = context.read<CustomerController>();

    final double pointsValue =
        customer.points * settings.settings.amountPerPoint;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: customer.points > 0
              ? Colors.amber.shade200
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: customer.points > 0
                      ? Colors.amber.shade100
                      : theme.colorScheme.primaryContainer,
                  child: customer.points > 0
                      ? const Icon(Icons.star, color: Colors.amber, size: 22)
                      : Text(
                          customer.name.isNotEmpty
                              ? customer.name.substring(0, 1)
                              : '؟',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              customer.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.star,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${customer.points} پۆینت',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(Icons.phone_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            customer.phone.isNotEmpty
                                ? customer.phone
                                : 'بێ ژمارەی مۆبایل',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String action) async {
                    if (action == 'points') {
                      _showAdjustPointsDialog(context, customer);
                    } else if (action == 'edit') {
                      openCustomerForm(context, initial: customer);
                    } else if (action == 'delete') {
                      final bool ok = await AppDialogs.confirm(
                        context,
                        title: 'سڕینەوەی کڕیار',
                        message: 'ئایا دڵنیایت لە سڕینەوەی "${customer.name}"؟',
                        confirmLabel: AppStrings.delete,
                        danger: true,
                      );
                      if (ok) {
                        await controller.deleteCustomer(customer.id);
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'points',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.stars, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text('دەستکاریکردنی پۆینت'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(AppStrings.edit),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(AppStrings.delete,
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'بەهای پۆینت: ${settings.money(pointsValue)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                Text(
                  'کۆی کڕین: ${settings.money(customer.totalSpent)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustPointsDialog(BuildContext context, Customer customer) {
    final TextEditingController pointsDeltaController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    bool isAdd = true;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return AlertDialog(
              title: Text('دەستکاریکردنی پۆینت — ${customer.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'پۆینتی ئێستای: ${customer.points} پۆینت ⭐',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('+ زیادکردن (دیاری)'),
                            selected: isAdd,
                            selectedColor: Colors.green.shade100,
                            onSelected: (_) =>
                                setModalState(() => isAdd = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('- کەمکردنەوە'),
                            selected: !isAdd,
                            selectedColor: Colors.red.shade100,
                            onSelected: (_) =>
                                setModalState(() => isAdd = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pointsDeltaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ژمارەی پۆینت',
                        prefixIcon: Icon(Icons.star_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'هۆکار (ئارەزوومەندانە)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final int pts =
                        int.tryParse(pointsDeltaController.text.trim()) ?? 0;
                    if (pts <= 0) return;
                    final int delta = isAdd ? pts : -pts;
                    await ctx.read<CustomerController>().manualAdjustPoints(
                          customer.id,
                          delta,
                          reason: reasonController.text.trim(),
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('پاشەکەوتکردن'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// فۆرمی دروستکردن یان دەستکاریکردنی کڕیار
Future<void> openCustomerForm(BuildContext context, {Customer? initial}) async {
  final CustomerController controller = context.read<CustomerController>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController(text: initial?.name ?? '');
  final TextEditingController phoneController =
      TextEditingController(text: initial?.phone ?? '');
  final TextEditingController noteController =
      TextEditingController(text: initial?.note ?? '');

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(initial == null ? 'کڕیاری نوێ' : 'دەستکاریکردنی کڕیار'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.customerName,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppStrings.required;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: AppStrings.customerPhone,
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: AppStrings.note,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final Customer customer = initial != null
                  ? initial.copyWith(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      note: noteController.text.trim(),
                      updatedAt: DateTime.now(),
                    )
                  : Customer(
                      id: 'cust-${DateTime.now().microsecondsSinceEpoch}',
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      note: noteController.text.trim(),
                      points: 0,
                      totalSpent: 0,
                      totalPointsEarned: 0,
                      totalPointsUsed: 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

              await controller.upsertCustomer(customer);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      );
    },
  );
}
