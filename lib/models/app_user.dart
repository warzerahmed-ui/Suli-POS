import '../core/app_strings.dart';
import '../core/password_hasher.dart';

/// ڕۆڵی بەکارهێنەر.
/// English: an admin may manage everything, a cashier only sells.
enum UserRole {
  admin(AppStrings.roleAdmin, AppStrings.roleAdminDesc),
  cashier(AppStrings.roleCashier, AppStrings.roleCashierDesc);

  const UserRole(this.label, this.description);

  final String label;
  final String description;

  bool get canManage => this == UserRole.admin;

  static UserRole fromName(String? name) => UserRole.values.firstWhere(
        (UserRole role) => role.name == name,
        orElse: () => UserRole.cashier,
      );
}

/// بەکارهێنەری سیستەم (بەڕێوەبەر یان کاشێر).
/// English: an application user. Passwords are stored as a SHA-256 hash.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.passwordHash,
    this.role = UserRole.cashier,
    this.isActive = true,
    this.createdAt,
  });

  /// بەکارهێنەری سەرەتایی: admin / admin123
  factory AppUser.defaultAdmin() => AppUser(
        id: 'user-admin',
        fullName: 'بەڕێوەبەری سیستەم',
        username: 'admin',
        passwordHash: PasswordHasher.hash('admin123'),
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

  final String id;
  final String fullName;
  final String username;
  final String passwordHash;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;

  bool get isAdmin => role == UserRole.admin;

  /// پیتەکانی سەرەتای ناو (بۆ ئاڤاتار).
  String get initials {
    final List<String> parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}';
  }

  bool matchesPassword(String password) =>
      PasswordHasher.verify(password, passwordHash);

  AppUser copyWith({
    String? fullName,
    String? username,
    String? passwordHash,
    UserRole? role,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'username': username,
        'passwordHash': passwordHash,
        'role': role.name,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        username: json['username'] as String? ?? '',
        passwordHash: json['passwordHash'] as String? ?? '',
        role: UserRole.fromName(json['role'] as String?),
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
      );
}
