import 'app_user.dart';

/// A logged-in session: the login token, when it expires, and whose it is.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAt;
  final AppUser user;

  /// @param now the current time
  /// @return whether the token has expired, so the user must log in again
  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// Parses the backend's register or login response.
  ///
  /// @param json the response body
  /// @return the session
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'user': user.toJson(),
  };
}
