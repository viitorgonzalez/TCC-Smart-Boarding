/// Convite resolvido pelo token — traz o que o aluno já enviou pra ele corrigir
/// em vez de redigitar tudo quando o cadastro é negado (RN14). A senha nunca
/// vem do backend: é sempre redigitada no reenvio.
class InviteInfoModel {
  final String email;
  final String status;
  final String? rejectionReason;
  final String? fullName;
  final String? institutionId;
  final String? course;
  final String? phone;
  final String? address;
  final String? birthDate;

  const InviteInfoModel({
    required this.email,
    required this.status,
    this.rejectionReason,
    this.fullName,
    this.institutionId,
    this.course,
    this.phone,
    this.address,
    this.birthDate,
  });

  bool get wasRejected => status == 'REJECTED';

  factory InviteInfoModel.fromJson(Map<String, dynamic> json) {
    return InviteInfoModel(
      email: json['email'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      fullName: json['fullName'] as String?,
      institutionId: json['institutionId'] as String?,
      course: json['course'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      birthDate: json['birthDate'] as String?,
    );
  }
}
