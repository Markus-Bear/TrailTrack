import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

/// Keeps the logged-in session between app launches.
abstract interface class SessionStore {
  /// @return the saved session, or null if there is none
  Future<AuthSession?> load();

  /// Saves [session], replacing any saved one.
  Future<void> save(AuthSession session);

  /// Removes the saved session, e.g. on log out.
  Future<void> clear();
}

/// Stores the session in the phone's encrypted storage (the Android
/// Keystore), so the login token is never kept in plain text.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> load() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } on Object {
      // Unreadable data, e.g. from an older app version: start logged out.
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(AuthSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
