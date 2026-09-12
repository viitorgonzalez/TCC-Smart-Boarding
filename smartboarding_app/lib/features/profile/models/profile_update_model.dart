/// Solicitação de alteração de perfil. Campo nulo = não foi pedida mudança
/// nele — distinguir "não pedi" de "pedi vazio" é o que evita apagar dado que
/// o aluno não quis mexer.
class ProfileUpdate {
  final String id;
  final String userId;
  final String? studentName;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? course;
  final String? institutionId;
  final String? birthDate;
  final String status;
  final String? rejectionReason;
  final String? createdAt;

  const ProfileUpdate({
    required this.id,
    required this.userId,
    required this.status,
    this.studentName,
    this.fullName,
    this.phone,
    this.address,
    this.course,
    this.institutionId,
    this.birthDate,
    this.rejectionReason,
    this.createdAt,
  });

  bool get pending => status == 'PENDING';
  bool get rejected => status == 'REJECTED';

  factory ProfileUpdate.fromJson(Map<String, dynamic> json) => ProfileUpdate(
    id: json['id'] as String,
    userId: json['userId'] as String,
    studentName: json['studentName'] as String?,
    fullName: json['fullName'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    course: json['course'] as String?,
    institutionId: json['institutionId'] as String?,
    birthDate: json['birthDate'] as String?,
    status: json['status'] as String,
    rejectionReason: json['rejectionReason'] as String?,
    createdAt: json['createdAt'] as String?,
  );

  /// Os campos efetivamente pedidos, prontos pra exibir na fila do admin.
  Map<String, String> get changes => {
    'Nome': ?fullName,
    'Telefone': ?phone,
    'Endereço': ?address,
    'Curso': ?course,
    'Nascimento': ?birthDate,
  };
}
