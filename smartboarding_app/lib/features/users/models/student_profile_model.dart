/// Perfil breve do aluno para o card do admin. Espelha o DTO da API — que não
/// manda e-mail, telefone, endereço nem data de nascimento.
class StudentProfile {
  final String id;
  final String fullName;
  final String? course;
  final String? institution;
  final bool isActive;
  final List<String> recentAttendance;
  final List<StatusChange> statusHistory;

  const StudentProfile({
    required this.id,
    required this.fullName,
    required this.isActive,
    this.course,
    this.institution,
    this.recentAttendance = const [],
    this.statusHistory = const [],
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    course: json['course'] as String?,
    institution: json['institution'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    recentAttendance: (json['recentAttendance'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
    statusHistory: (json['statusHistory'] as List? ?? const [])
        .map((e) => StatusChange.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class StatusChange {
  /// `ACTIVATED` ou `DEACTIVATED`.
  final String action;
  final String? adminName;
  final String at;

  const StatusChange({required this.action, required this.at, this.adminName});

  bool get activated => action == 'ACTIVATED';

  factory StatusChange.fromJson(Map<String, dynamic> json) => StatusChange(
    action: json['action'] as String,
    adminName: json['adminName'] as String?,
    at: json['at'] as String,
  );
}
