import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/services/auth_api.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';

import '../helpers/fake_auth.dart';

void main() {
  test('logging in signs the user in and saves the session', () async {
    final store = InMemorySessionStore();
    final auth = AuthViewModel(api: FakeAuthApi(), store: store);

    final ok = await auth.login(email: ' hiker@example.com ', password: 'pw');

    expect(ok, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.user?.displayName, 'Markus');
    expect(auth.accessToken, 'signed-token');
    expect(store.saved, isNotNull);
  });

  test(
    'a failed login keeps the user a guest and exposes the errors',
    () async {
      final auth = AuthViewModel(
        api: FakeAuthApi(
          error: const AuthApiException(
            'Some fields are invalid',
            fieldErrors: {'email': 'Email is not valid'},
          ),
        ),
        store: InMemorySessionStore(),
      );

      final ok = await auth.login(email: 'x', password: 'pw');

      expect(ok, isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.error, 'Some fields are invalid');
      expect(auth.fieldErrors['email'], 'Email is not valid');
      expect(auth.busy, isFalse);
    },
  );

  test('registering signs the new user in', () async {
    final api = FakeAuthApi();
    final auth = AuthViewModel(api: api, store: InMemorySessionStore());

    final ok = await auth.register(
      displayName: ' Markus ',
      email: 'hiker@example.com',
      password: 'correct horse',
    );

    expect(ok, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(api.calls.single, 'register Markus hiker@example.com');
  });

  test('logging out forgets the saved session', () async {
    final store = InMemorySessionStore(testSession());
    final auth = AuthViewModel(api: FakeAuthApi(), store: store);
    await auth.restore();

    await auth.logout();

    expect(auth.isLoggedIn, isFalse);
    expect(store.saved, isNull);
  });

  test('a saved session is restored on start until it expires', () async {
    final issued = DateTime(2026, 10, 19, 9);
    final session = testSession(issuedAt: issued);

    final dayLater = AuthViewModel(
      api: FakeAuthApi(),
      store: InMemorySessionStore(session),
      clock: () => issued.add(const Duration(days: 1)),
    );
    await dayLater.restore();
    expect(dayLater.isLoggedIn, isTrue);

    final store = InMemorySessionStore(session);
    final weekLater = AuthViewModel(
      api: FakeAuthApi(),
      store: store,
      clock: () => issued.add(const Duration(days: 8)),
    );
    await weekLater.restore();
    expect(weekLater.isLoggedIn, isFalse);
    expect(store.saved, isNull);
  });
}
