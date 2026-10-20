import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../services/auth_api.dart';
import '../services/session_store.dart';

/// Who is logged in, shared by every screen. Logging in is never required:
/// with no session the user is a guest.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this._api,
    required this._store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthApi _api;
  final SessionStore _store;
  final DateTime Function() _clock;

  AuthSession? _session;
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  bool get isLoggedIn => _session != null;
  AppUser? get user => _session?.user;

  /// The login token to send with requests that need one.
  String? get accessToken => _session?.accessToken;

  /// Whether a login or registration is in progress.
  bool get busy => _busy;

  /// Why the last login or registration failed, or null.
  String? get error => _error;

  /// Messages for fields the backend rejected in the last attempt.
  Map<String, String> get fieldErrors => _fieldErrors;

  /// Restores the session saved by an earlier launch, unless it has expired.
  /// Works offline, since nothing is sent to the backend.
  Future<void> restore() async {
    final saved = await _store.load();
    if (saved == null) return;
    if (saved.isExpiredAt(_clock())) {
      await _store.clear();
      return;
    }
    _session = saved;
    notifyListeners();
  }

  /// @return whether the user is now logged in
  Future<bool> login({required String email, required String password}) =>
      _signIn(() => _api.login(email: email.trim(), password: password));

  /// @return whether the account was created and the user is logged in
  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
  }) => _signIn(
    () => _api.register(
      displayName: displayName.trim(),
      email: email.trim(),
      password: password,
    ),
  );

  /// Logs out, forgetting the saved session.
  Future<void> logout() async {
    _session = null;
    await _store.clear();
    notifyListeners();
  }

  /// Forgets the last attempt's errors, e.g. when a form is opened.
  void clearErrors() {
    if (_error == null && _fieldErrors.isEmpty) return;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  Future<bool> _signIn(Future<AuthSession> Function() request) async {
    _busy = true;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      final session = await request();
      await _store.save(session);
      _session = session;
      return true;
    } on AuthApiException catch (e) {
      _error = e.message;
      _fieldErrors = e.fieldErrors;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
