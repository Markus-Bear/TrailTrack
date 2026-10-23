import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:trailtrack/models/app_user.dart';
import 'package:trailtrack/models/auth_session.dart';
import 'package:trailtrack/services/auth_api.dart';
import 'package:trailtrack/services/session_store.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';

/// A session for the test hiker, valid for a week from [issuedAt].
AuthSession testSession({DateTime? issuedAt}) => AuthSession(
  accessToken: 'signed-token',
  expiresAt: (issuedAt ?? DateTime.now()).add(const Duration(days: 7)),
  user: const AppUser(
    id: 5,
    displayName: 'Markus',
    email: 'hiker@example.com',
    role: 'HIKER',
  ),
);

/// Keeps the session in memory instead of the phone's secure storage.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this.saved]);

  AuthSession? saved;

  @override
  Future<AuthSession?> load() async => saved;

  @override
  Future<void> save(AuthSession session) async => saved = session;

  @override
  Future<void> clear() async => saved = null;
}

/// Answers login and registration with [result], or throws [error].
class FakeAuthApi extends AuthApi {
  FakeAuthApi({this.error});

  AuthApiException? error;
  final calls = <String>[];

  Future<AuthSession> _answer(String call) async {
    calls.add(call);
    if (error != null) throw error!;
    return testSession();
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _answer('login $email');

  @override
  Future<AuthSession> register({
    required String displayName,
    required String email,
    required String password,
  }) => _answer('register $displayName $email');
}

/// Provides [auth], or a guest session, to [child].
Widget withAuth(Widget child, {AuthViewModel? auth}) =>
    ChangeNotifierProvider.value(
      value:
          auth ??
          AuthViewModel(api: FakeAuthApi(), store: InMemorySessionStore()),
      child: child,
    );
