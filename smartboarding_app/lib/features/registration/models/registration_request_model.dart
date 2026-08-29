/// Pedido de cadastro na visão do admin — carrega tudo que o aluno enviou pra
/// a conferência acontecer antes de aprovar ou negar.
class RegistrationRequestModel {
  final String id;
  final String email;
  final String? fullName;
  final String? institutionId;
  final String? institutionName;
  final String? course;
  final String? phone;
  final String? address;
  final String? birthDate;
  final String createdAt;

  const RegistrationRequestModel({
    required this.id,
    required this.email,
    this.fullName,
    this.institutionId,
    this.institutionName,
    this.course,
    this.phone,
    this.address,
    this.birthDate,
    required this.createdAt,
  });

  factory RegistrationRequestModel.fromJson(Map<String, dynamic> json) {
    return RegistrationRequestModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      institutionId: json['institutionId'] as String?,
      institutionName: json['institutionName'] as String?,
      course: json['course'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      birthDate: json['birthDate'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}
