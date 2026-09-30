import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../models/app_user.dart';
import '../state/auth_controller.dart';
import '../widgets/app_widgets.dart';

/// شاشەی بەکارهێنەران: زیادکردن، دەستکاری و سڕینەوە (تەنها بەڕێوەبەر).
/// English: user management. Only admins reach this screen (see `AppShell`).
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final List<AppUser> users = auth.users;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${AppStrings.users}: ${users.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => openUserForm(context),
                icon: const Icon(Icons.person_add_alt),
                label: const Text(AppStrings.addUser),
              ),
            ],
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: AppStrings.noData,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) =>
                      _UserTile(user: users[index]),
                ),
        ),
      ],
    );
  }
}

/// کارتی بەکارهێنەرێک لەگەڵ کردارەکان.
class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthController auth = context.read<AuthController>();
    final bool isSelf = auth.currentUser?.id == user.id;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isAdmin
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.secondary.withValues(alpha: 0.15),
          child: Text(
            user.initials,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                user.fullName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isSelf)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Chip(
                  label: const Text(AppStrings.welcomeBack),
                  labelStyle: theme.textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('${AppStrings.username}: ${user.username}'),
              Chip(
                label: Text(user.role.label),
                labelStyle: theme.textTheme.labelSmall,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                user.isActive ? AppStrings.active : AppStrings.inactive,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: user.isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (user.createdAt != null)
                Text(
                  '${AppStrings.date}: ${Formatters.date(user.createdAt!)}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: AppStrings.actions,
          onSelected: (String value) => _handle(context, value, auth),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text(AppStrings.edit),
            ),
            PopupMenuItem<String>(
              value: 'toggle',
              child: Text(
                user.isActive ? AppStrings.inactive : AppStrings.active,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                AppStrings.delete,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    String action,
    AuthController auth,
  ) async {
    switch (action) {
      case 'edit':
        {
          await openUserForm(context, user: user);
        }
      case 'toggle':
        {
          final String? error = auth.saveUser(
            existing: user,
            fullName: user.fullName,
            username: user.username,
            role: user.role,
            isActive: !user.isActive,
          );
          if (error != null && context.mounted) {
            AppDialogs.showMessage(context, error, isError: true);
          }
        }
      case 'delete':
        {
          final bool confirmed = await AppDialogs.confirm(
            context,
            message: AppStrings.deleteUserConfirm,
            confirmLabel: AppStrings.delete,
            danger: true,
          );
          if (!confirmed || !context.mounted) return;
          final String? error = auth.deleteUser(user.id);
          if (!context.mounted) return;
          if (error != null) {
            AppDialogs.showMessage(context, error, isError: true);
          }
        }
    }
  }
}

/// ئەنجامی فۆرمی بەکارهێنەر.
class _UserFormOutcome {
  const _UserFormOutcome({required this.saved, this.error});

  final bool saved;
  final String? error;
}

/// کردنەوەی فۆرمی بەکارهێنەر (زیادکردن یان دەستکاری).
Future<void> openUserForm(BuildContext context, {AppUser? user}) async {
  final _UserFormOutcome? outcome = await showDialog<_UserFormOutcome>(
    context: context,
    builder: (BuildContext dialogContext) => _UserFormDialog(user: user),
  );
  if (outcome == null || !context.mounted) return;
  if (outcome.saved) {
    AppDialogs.showMessage(context, AppStrings.userSaved);
    return;
  }
  if (outcome.error != null) {
    AppDialogs.showMessage(context, outcome.error!, isError: true);
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.user});

  final AppUser? user;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();

  late UserRole _role;
  late bool _isActive;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );
    _role = widget.user?.role ?? UserRole.cashier;
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String? error = context.read<AuthController>().saveUser(
      existing: widget.user,
      fullName: _nameController.text,
      username: _usernameController.text,
      role: _role,
      isActive: _isActive,
      password: _passwordController.text,
    );
    if (error != null) {
      Navigator.of(context).pop(_UserFormOutcome(saved: false, error: error));
      return;
    }
    Navigator.of(context).pop(const _UserFormOutcome(saved: true));
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.user == null;

    return AlertDialog(
      title: Text(isNew ? AppStrings.addUser : AppStrings.editUser),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.fullName,
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.username,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.required;
                    }
                    if (value.trim().length < 3) return AppStrings.passwordHint;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: isNew
                        ? AppStrings.password
                        : '${AppStrings.changePassword} '
                              '(${AppStrings.optional})',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (String? value) {
                    if (isNew && (value == null || value.isEmpty)) {
                      return AppStrings.required;
                    }
                    if (value != null && value.isNotEmpty && value.length < 4) {
                      return AppStrings.passwordHint;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: AppStrings.role,
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  items: UserRole.values
                      .map(
                        (UserRole role) => DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text('${role.label} — ${role.description}'),
                        ),
                      )
                      .toList(),
                  onChanged: (UserRole? value) =>
                      setState(() => _role = value ?? UserRole.cashier),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (bool value) => setState(() => _isActive = value),
                  title: const Text(AppStrings.activeAccount),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
