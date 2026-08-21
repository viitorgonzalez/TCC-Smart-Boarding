class RegistrationRequestModel {
  final String id;
  final String email;
  final String? fullName;
  final String? institutionId;
  final String createdAt;

  const RegistrationRequestModel({
    required this.id,
    required this.email,
    this.fullName,
    this.institutionId,
    required this.createdAt,
  });

  factory RegistrationRequestModel.fromJson(Map<String, dynamic> json) {
    return RegistrationRequestModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      institutionId: json['institutionId'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}
