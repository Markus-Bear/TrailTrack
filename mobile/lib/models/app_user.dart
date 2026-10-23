/// A TrailTrack account, as returned by the backend.
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
  });

  final int id;
  final String displayName;
  final String email;

  /// HIKER or ADMIN.
  final String role;

  /// Parses the backend's account JSON.
  ///
  /// @param json the account object, e.g. the "user" field of a login response
  /// @return the account
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['id'] as num).toInt(),
    displayName: json['displayName'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'role': role,
  };
}
