import 'address_model.dart';

class ProfileUpdate {
  final String id;
  final String userId;
  final String? studentName;
  final String? fullName;
  final String? phone;
  final Address? address;
  final String? course;
  final String? institutionId;
  final String? birthDate;
  final String status;
  final String? rejectionReason;
  final String? createdAt;

  final ProfileBefore before;

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
    this.before = const ProfileBefore(),
  });

  bool get pending => status == 'PENDING';
  bool get rejected => status == 'REJECTED';

  factory ProfileUpdate.fromJson(Map<String, dynamic> json) {
    final semEndereco =
        json['zipCode'] == null &&
        json['street'] == null &&
        json['neighborhood'] == null &&
        json['city'] == null &&
        json['state'] == null &&
        json['streetNumber'] == null &&
        json['complement'] == null;

    return ProfileUpdate(
      id: json['id'] as String,
      userId: json['userId'] as String,
      studentName: json['studentName'] as String?,
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      address: semEndereco
          ? null
          : Address(
              zipCode: json['zipCode'] as String?,
              street: json['street'] as String?,
              neighborhood: json['neighborhood'] as String?,
              city: json['city'] as String?,
              state: json['state'] as String?,
              streetNumber: json['streetNumber'] as String?,
              complement: json['complement'] as String?,
            ),
      course: json['course'] as String?,
      institutionId: json['institutionId'] as String?,
      birthDate: json['birthDate'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String?,
      before: ProfileBefore.fromJson(json['before'] as Map<String, dynamic>?),
    );
  }

  Map<String, String> get changes => {
    'Nome': ?fullName,
    'Telefone': ?phone,
    if (address != null) 'Endereço': _resumoEndereco(address!),
    'Curso': ?course,
    'Nascimento': ?birthDate,
  };

  List<ProfileFieldDiff> get diffs => [
    if (fullName != null)
      ProfileFieldDiff('Nome', before.fullName ?? '—', fullName!),
    if (phone != null)
      ProfileFieldDiff('Telefone', before.phone ?? '—', phone!),
    if (address != null)
      ProfileFieldDiff(
        'Endereço',
        before.address == null ? '—' : _resumoEndereco(before.address!),
        _resumoEndereco(address!),
      ),
    if (course != null)
      ProfileFieldDiff('Curso', before.course ?? '—', course!),
    if (birthDate != null)
      ProfileFieldDiff('Nascimento', before.birthDate ?? '—', birthDate!),
  ];

  static String _resumoEndereco(Address a) {
    final partes = [
      if (a.street != null) a.street!,
      if (a.streetNumber != null) a.streetNumber!,
      if (a.neighborhood != null) a.neighborhood!,
    ];
    return partes.isEmpty ? '(pedido)' : partes.join(', ');
  }
}

class ProfileFieldDiff {
  final String label;
  final String before;
  final String after;
  const ProfileFieldDiff(this.label, this.before, this.after);
}

class ProfileBefore {
  final String? fullName;
  final String? phone;
  final String? course;
  final String? birthDate;
  final Address? address;

  const ProfileBefore({
    this.fullName,
    this.phone,
    this.course,
    this.birthDate,
    this.address,
  });

  factory ProfileBefore.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProfileBefore();
    final semEndereco =
        json['zipCode'] == null &&
        json['street'] == null &&
        json['neighborhood'] == null &&
        json['city'] == null &&
        json['state'] == null &&
        json['streetNumber'] == null &&
        json['complement'] == null;

    return ProfileBefore(
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      course: json['course'] as String?,
      birthDate: json['birthDate'] as String?,
      address: semEndereco
          ? null
          : Address(
              zipCode: json['zipCode'] as String?,
              street: json['street'] as String?,
              neighborhood: json['neighborhood'] as String?,
              city: json['city'] as String?,
              state: json['state'] as String?,
              streetNumber: json['streetNumber'] as String?,
              complement: json['complement'] as String?,
            ),
    );
  }
}

class Me {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool hasPassword;
  final bool hasGoogle;
  final String? phone;
  final String? course;
  final Address address;

  final List<String> missingForList;

  final String? institution;

  const Me({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.hasPassword,
    required this.hasGoogle,
    this.phone,
    this.course,
    this.address = const Address(),
    this.missingForList = const [],
    this.institution,
  });

  bool get profileCompleteForList => missingForList.isEmpty;

  static const rotulos = <String, String>{
    'fullName': 'Nome completo',
    'phone': 'Telefone',
    'address': 'Endereço',
    'institution': 'Instituição',
  };

  List<String> get faltandoEmPortugues => [
    for (final campo in missingForList) rotulos[campo] ?? campo,
  ];

  factory Me.fromJson(Map<String, dynamic> json) => Me(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    hasPassword: json['hasPassword'] as bool? ?? true,
    hasGoogle: json['hasGoogle'] as bool? ?? false,
    phone: json['phone'] as String?,
    course: json['course'] as String?,
    address: json['address'] == null
        ? const Address()
        : Address.fromJson(json['address'] as Map<String, dynamic>),
    missingForList:
        (json['missingForList'] as List?)?.map((e) => e as String).toList() ??
        const [],
    institution: json['institution'] as String?,
  );
}
