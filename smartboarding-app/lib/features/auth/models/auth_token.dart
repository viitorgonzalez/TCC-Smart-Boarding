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

  factory AuthToken.fromLogin(Map<String, dynamic> json, String email) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthToken(
      token: data['token'] as String,
      fullName: data['fullName'] as String,
      role: data['role'] as String,
      email: email,
    );
  }

  bool get isAdmin => role == 'ADMIN';
}
