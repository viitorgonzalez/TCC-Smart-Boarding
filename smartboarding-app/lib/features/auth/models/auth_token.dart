class AuthToken {
  final String token;
  final String fullName;
  final String role;

  const AuthToken({
    required this.token,
    required this.fullName,
    required this.role,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthToken(
      token: data['token'] as String,
      fullName: data['fullName'] as String,
      role: data['role'] as String,
    );
  }

  bool get isAdmin => role == 'ADMIN';
}
