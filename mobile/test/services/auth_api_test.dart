import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailtrack/services/auth_api.dart';

const _session = {
  'accessToken': 'signed-token',
  'expiresAt': '2026-10-26T12:00:00Z',
  'user': {
    'id': 5,
    'displayName': 'Markus',
    'email': 'hiker@example.com',
    'role': 'HIKER',
  },
};

AuthApi _apiAnswering(int status, Object body, {List<http.Request>? sent}) =>
    AuthApi(
      baseUrl: 'http://backend',
      client: MockClient((request) async {
        sent?.add(request);
        return http.Response(jsonEncode(body), status);
      }),
    );

Future<AuthApiException> _errorFrom(Future<void> call) async {
  try {
    await call;
  } on AuthApiException catch (e) {
    return e;
  }
  fail('Expected AuthApiException');
}

void main() {
  test('login posts the email and password and parses the session', () async {
    final sent = <http.Request>[];
    final session = await _apiAnswering(
      200,
      _session,
      sent: sent,
    ).login(email: 'hiker@example.com', password: 'correct horse');

    expect(sent.single.url.toString(), 'http://backend/api/auth/login');
    expect(jsonDecode(sent.single.body), {
      'email': 'hiker@example.com',
      'password': 'correct horse',
    });
    expect(session.accessToken, 'signed-token');
    expect(session.expiresAt, DateTime.utc(2026, 10, 26, 12));
    expect(session.user.displayName, 'Markus');
  });

  test('register posts to /api/auth/register and accepts 201', () async {
    final sent = <http.Request>[];
    final session = await _apiAnswering(201, _session, sent: sent).register(
      displayName: 'Markus',
      email: 'hiker@example.com',
      password: 'correct horse',
    );

    expect(sent.single.url.path, '/api/auth/register');
    expect(session.user.email, 'hiker@example.com');
  });

  test('a rejected login reports the backend message', () async {
    final error = await _errorFrom(
      _apiAnswering(401, {
        'detail': 'Email or password is incorrect',
      }).login(email: 'hiker@example.com', password: 'wrong horse'),
    );

    expect(error.message, 'Email or password is incorrect');
    expect(error.fieldErrors, isEmpty);
  });

  test('validation errors are reported per field', () async {
    final error = await _errorFrom(
      _apiAnswering(400, {
        'detail': 'Some fields are invalid',
        'errors': {
          'email': 'Email is not valid',
          'passwordWithinBcryptLimit': 'Password is too long',
        },
      }).register(displayName: 'Markus', email: 'x', password: 'p'),
    );

    expect(error.fieldErrors, {
      'email': 'Email is not valid',
      'password': 'Password is too long',
    });
  });

  test('an unreachable server gives a connection message', () async {
    final api = AuthApi(
      baseUrl: 'http://backend',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    final error = await _errorFrom(
      api.login(email: 'hiker@example.com', password: 'correct horse'),
    );

    expect(error.message, contains('Could not reach the server'));
  });
}
