class AuthToken {
  final String token;
  final String fullName;
  final String role;
  final String email;

  const AuthToken({
    required this.token,
    required this.fullName,
    required this.role,
    required this.email,
  });

  /// [email] é passado separadamente pois a API não o retorna no LoginResponse.
  factory AuthToken.fromLogin(Map<String, dynamic> json, String email) {
    return AuthToken(
      token: json['token'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      email: email,
    );
  }
}
