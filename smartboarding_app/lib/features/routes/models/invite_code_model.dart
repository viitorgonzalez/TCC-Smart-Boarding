class InviteCode {
  final String id;
  final String code;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final bool usable;
  final int uses;

  final String? institutionId;

  final String? institutionName;

  final String? routeName;
  final String? routeId;

  const InviteCode({
    required this.id,
    required this.code,
    required this.usable,
    required this.uses,
    this.expiresAt,
    this.revokedAt,
    this.institutionId,
    this.institutionName,
    this.routeName,
    this.routeId,
  });

  bool get revoked => revokedAt != null;

  bool get aberto => institutionId == null;
  bool get expired => !usable && !revoked;

  factory InviteCode.fromJson(Map<String, dynamic> json) => InviteCode(
    id: json['id'] as String,
    code: json['code'] as String,
    usable: json['usable'] as bool? ?? false,
    uses: (json['uses'] as num?)?.toInt() ?? 0,
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
    revokedAt: json['revokedAt'] == null
        ? null
        : DateTime.parse(json['revokedAt'] as String),
    institutionId: json['institutionId'] as String?,
    institutionName: json['institutionName'] as String?,
    routeName: json['routeName'] as String?,
    routeId: json['routeId'] as String?,
  );
}

enum CodeValidity {
  umDia('1 dia', 1),
  seteDias('7 dias', 7),
  trintaDias('30 dias', 30),
  semestre('Semestre', 180);

  const CodeValidity(this.label, this.days);

  final String label;
  final int days;

  DateTime expiresFrom(DateTime now) => now.add(Duration(days: days));
}
