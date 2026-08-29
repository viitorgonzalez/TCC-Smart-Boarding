class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;

  /// Nome da instituição, resolvido pelo backend a partir da referência.
  final String? institution;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.institution,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      institution: json['institution'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
