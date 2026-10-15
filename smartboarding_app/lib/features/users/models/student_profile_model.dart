class StudentProfile {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? birthDate;
  final String? course;
  final String? institution;
  final bool isActive;
  final String role;
  final List<String> recentAttendance;
  final List<StatusChange> statusHistory;

  const StudentProfile({
    required this.id,
    required this.fullName,
    required this.isActive,
    required this.role,
    this.email,
    this.phone,
    this.address,
    this.birthDate,
    this.course,
    this.institution,
    this.recentAttendance = const [],
    this.statusHistory = const [],
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    address: _endereco(json['address']),
    birthDate: json['birthDate'] as String?,
    course: json['course'] as String?,
    institution: json['institution'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    role: json['role'] as String,
    recentAttendance: (json['recentAttendance'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
    statusHistory: (json['statusHistory'] as List? ?? const [])
        .map((e) => StatusChange.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// O endereço virou objeto quando o cadastro passou a ser estruturado; antes
/// era texto livre. Ler só uma das formas estourava TypeError e a tela do admin
/// ficava presa carregando, porque quem chama engole a exceção.
String? _endereco(Object? raw) => switch (raw) {
  String texto when texto.isNotEmpty => texto,
  Map<String, dynamic> mapa => switch (mapa['fullForm'] as String?) {
    final String completo when completo.isNotEmpty => completo,
    _ => null,
  },
  _ => null,
};

class StatusChange {
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
