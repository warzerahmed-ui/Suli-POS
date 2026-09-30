import 'package:flutter/foundation.dart';

import '../core/app_strings.dart';
import '../core/password_hasher.dart';
import '../data/demo_data.dart';
import '../data/pos_repository.dart';
import '../models/app_user.dart';

/// کۆنترۆڵەری چوونەژوورەوە و بەڕێوەبردنی بەکارهێنەران.
///
/// English: handles sign-in/sign-out and user CRUD. The first time the app runs
/// it creates the default users (admin/cashier) so the app is never locked out.
class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final PosRepository _repository;

  List<AppUser> _users = <AppUser>[];
  AppUser? _currentUser;

  List<AppUser> get users => List<AppUser>.unmodifiable(_users);

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  bool get isAdmin => _currentUser?.isAdmin ?? false;

  void load() {
    _users = _repository.loadUsers();
    if (_users.isEmpty) {
      _users = DemoData.users();
      _persist();
    }
    notifyListeners();
  }

  /// گەڕانەوەی هەڵە (یان `null` ئەگەر سەرکەوتوو بوو).
  String? signIn(String username, String password) {
    final String normalized = username.trim().toLowerCase();
    final int index = _users.indexWhere(
      (AppUser user) => user.username.toLowerCase() == normalized,
    );
    if (index < 0) return AppStrings.wrongCredentials;
    final AppUser user = _users[index];
    if (!user.matchesPassword(password)) return AppStrings.wrongCredentials;
    if (!user.isActive) return AppStrings.inactiveUser;
    _currentUser = user;
    notifyListeners();
    return null;
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  /// زیادکردن یان نوێکردنەوەی بەکارهێنەر. ئەگەر `password` بدرێت هاش دەکرێت.
  String? saveUser({
    AppUser? existing,
    required String fullName,
    required String username,
    required UserRole role,
    required bool isActive,
    String? password,
  }) {
    final String cleanUsername = username.trim();
    final bool taken = _users.any(
      (AppUser user) =>
          user.id != existing?.id &&
          user.username.toLowerCase() == cleanUsername.toLowerCase(),
    );
    if (taken) return AppStrings.usernameTaken;

    final AppUser userToSave;
    if (existing == null) {
      userToSave = AppUser(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        fullName: fullName.trim(),
        username: cleanUsername,
        passwordHash: PasswordHasher.hash(password ?? '1234'),
        role: role,
        isActive: isActive,
        createdAt: DateTime.now(),
      );
      _users = <AppUser>[..._users, userToSave];
    } else {
      userToSave = existing.copyWith(
        fullName: fullName.trim(),
        username: cleanUsername,
        role: role,
        isActive: isActive,
        passwordHash: (password == null || password.isEmpty)
            ? existing.passwordHash
            : PasswordHasher.hash(password),
      );
      _users = _users
          .map((AppUser user) => user.id == userToSave.id ? userToSave : user)
          .toList();
      if (_currentUser?.id == userToSave.id) _currentUser = userToSave;
    }
    _repository.saveSingleUser(userToSave);
    notifyListeners();
    return null;
  }

  /// سڕینەوەی بەکارهێنەر بە مەرجی ئەوەی خۆی و کۆتا بەڕێوەبەر نەبێت.
  String? deleteUser(String id) {
    if (_currentUser?.id == id) return AppStrings.cantDeleteSelf;
    AppUser? target;
    for (final AppUser user in _users) {
      if (user.id == id) {
        target = user;
        break;
      }
    }
    if (target == null) return null;
    final bool removingAdmin = target.isAdmin;
    final int adminCount =
        _users.where((AppUser user) => user.isAdmin).length;
    if (removingAdmin && adminCount <= 1) return AppStrings.cantDeleteSelf;
    _users = _users.where((AppUser user) => user.id != id).toList();
    _repository.deleteSingleUser(id);
    notifyListeners();
    return null;
  }

  void _persist() {
    _repository.saveUsers(_users);
  }
}
