class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}
