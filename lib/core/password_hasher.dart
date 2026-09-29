import 'dart:convert';

import 'package:crypto/crypto.dart';

/// هاشکردنی وشەی نهێنی بە SHA-256 لەگەڵ «خوێ» (salt).
///
/// English: passwords are never stored in clear text. This is still a local
/// demo store (SharedPreferences), so treat the file as sensitive.
class PasswordHasher {
  const PasswordHasher._();

  static const String _salt = 'pos_system_v1';

  static String hash(String password) =>
      sha256.convert(utf8.encode('$_salt::$password')).toString();

  static bool verify(String password, String storedHash) =>
      hash(password) == storedHash;
}
