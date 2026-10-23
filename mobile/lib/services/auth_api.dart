import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/auth_session.dart';

/// Thrown when registering or logging in fails.
class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.fieldErrors = const {}});

  /// A message that can be shown to the user.
  final String message;

  /// Messages for individual fields the backend rejected, keyed by field
  /// name (displayName, email, password).
  final Map<String, String> fieldErrors;

  @override
  String toString() => 'AuthApiException: $message';
}

/// Client for the backend's account endpoints.
class AuthApi {
  /// @param baseUrl backend base URL, defaults to [apiBaseUrl]
  AuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Creates an account and signs the user in.
  ///
  /// @return the new session
  /// @throws AuthApiException if the details are rejected, the email is
  ///         already registered, or the server cannot be reached
  Future<AuthSession> register({
    required String displayName,
    required String email,
    required String password,
  }) => _post('/api/auth/register', {
    'displayName': displayName,
    'email': email,
    'password': password,
  });

  /// Logs in with an email and password.
  ///
  /// @return the new session
  /// @throws AuthApiException if the email or password is wrong, or the
  ///         server cannot be reached
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _post('/api/auth/login', {'email': email, 'password': password});

  Future<AuthSession> _post(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const AuthApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthSession.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw _errorFrom(response);
  }

  /// The backend reports its BCrypt length check under its own name; it
  /// belongs to the password field.
  static const _fieldNames = {'passwordWithinBcryptLimit': 'password'};

  /// Reads the backend's problem detail: its "detail" message and, for
  /// validation failures, its per-field "errors".
  AuthApiException _errorFrom(http.Response response) {
    try {
      final problem = jsonDecode(response.body) as Map<String, dynamic>;
      final errors = (problem['errors'] as Map<String, dynamic>?) ?? const {};
      return AuthApiException(
        problem['detail'] as String? ??
            'Something went wrong. Please try again.',
        fieldErrors: errors.map(
          (field, message) => MapEntry(_fieldNames[field] ?? field, '$message'),
        ),
      );
    } on FormatException {
      return const AuthApiException('Something went wrong. Please try again.');
    }
  }
}
