import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/screens/login_screen.dart';
import 'package:trailtrack/screens/register_screen.dart';
import 'package:trailtrack/services/auth_api.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';

import '../helpers/fake_auth.dart';

/// Opens [screen] on top of a home page, as the map would.
Future<void> _open(
  WidgetTester tester,
  Widget screen,
  AuthViewModel auth,
) async {
  await tester.pumpWidget(
    withAuth(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => screen)),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
      auth: auth,
    ),
  );
  await tester.tap(find.text('Home'));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('log in checks the fields before contacting the server', (
    tester,
  ) async {
    final api = FakeAuthApi();
    await _open(
      tester,
      const LoginScreen(),
      AuthViewModel(api: api, store: InMemorySessionStore()),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('logging in returns to the home screen, signed in', (
    tester,
  ) async {
    final auth = AuthViewModel(
      api: FakeAuthApi(),
      store: InMemorySessionStore(),
    );
    await _open(tester, const LoginScreen(), auth);

    await tester.enterText(_field('Email'), 'hiker@example.com');
    await tester.enterText(_field('Password'), 'correct horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(auth.isLoggedIn, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a wrong email or password is shown on the login screen', (
    tester,
  ) async {
    final auth = AuthViewModel(
      api: FakeAuthApi(
        error: const AuthApiException('Email or password is incorrect'),
      ),
      store: InMemorySessionStore(),
    );
    await _open(tester, const LoginScreen(), auth);

    await tester.enterText(_field('Email'), 'hiker@example.com');
    await tester.enterText(_field('Password'), 'wrong horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect'), findsOneWidget);
    expect(auth.isLoggedIn, isFalse);
  });

  testWidgets('register needs a password of at least 8 characters', (
    tester,
  ) async {
    final api = FakeAuthApi();
    await _open(
      tester,
      const RegisterScreen(),
      AuthViewModel(api: api, store: InMemorySessionStore()),
    );

    await tester.enterText(_field('Display name'), 'Markus');
    await tester.enterText(_field('Email'), 'hiker@example.com');
    await tester.enterText(_field('Password'), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('an email that is already registered is shown under the field', (
    tester,
  ) async {
    final auth = AuthViewModel(
      api: FakeAuthApi(
        error: const AuthApiException(
          'An account with this email already exists',
          fieldErrors: {'email': 'An account with this email already exists'},
        ),
      ),
      store: InMemorySessionStore(),
    );
    await _open(tester, const RegisterScreen(), auth);

    await tester.enterText(_field('Display name'), 'Markus');
    await tester.enterText(_field('Email'), 'hiker@example.com');
    await tester.enterText(_field('Password'), 'correct horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('An account with this email already exists'),
      findsOneWidget,
    );
  });

  testWidgets('creating an account returns to the home screen, signed in', (
    tester,
  ) async {
    final auth = AuthViewModel(
      api: FakeAuthApi(),
      store: InMemorySessionStore(),
    );
    await _open(tester, const RegisterScreen(), auth);

    await tester.enterText(_field('Display name'), 'Markus');
    await tester.enterText(_field('Email'), 'hiker@example.com');
    await tester.enterText(_field('Password'), 'correct horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(auth.isLoggedIn, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });
}
