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

  factory AuthToken.fromLogin(
    Map<String, dynamic> json, [
    String fallbackEmail = '',
  ]) {
    final doServidor = json['email'] as String?;
    return AuthToken(
      token: json['token'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      email: (doServidor == null || doServidor.isEmpty)
          ? fallbackEmail
          : doServidor,
    );
  }
}
