/// Código que o admin distribui pra quem vai entrar na rota.
///
/// [uses] é quantos alunos já entraram por ele — é o que diz se o código
/// circulou ou se ninguém recebeu. [usable] vem pronto do backend porque
/// "vale ou não vale" depende do relógio do servidor, não do aparelho.
class InviteCode {
  final String id;
  final String code;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final bool usable;
  final int uses;

  const InviteCode({
    required this.id,
    required this.code,
    required this.usable,
    required this.uses,
    this.expiresAt,
    this.revokedAt,
  });

  bool get revoked => revokedAt != null;
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
  );
}

/// Por quanto tempo um código novo vale. O rótulo é o que o admin lê; os dias
/// viram a data que o backend guarda.
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
