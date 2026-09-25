/// Endereço do aluno, campo a campo.
///
/// [complete] e [shortForm] vêm calculados do backend de propósito: a regra de
/// "endereço completo" decide se o aluno entra na lista, e duas versões dela —
/// uma em Java, outra aqui — divergiriam na primeira mudança.
class Address {
  final String? zipCode;
  final String? street;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? streetNumber;
  final String? complement;
  final bool complete;
  final String shortForm;

  const Address({
    this.zipCode,
    this.street,
    this.neighborhood,
    this.city,
    this.state,
    this.streetNumber,
    this.complement,
    this.complete = false,
    this.shortForm = '',
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    zipCode: json['zipCode'] as String?,
    street: json['street'] as String?,
    neighborhood: json['neighborhood'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    streetNumber: json['streetNumber'] as String?,
    complement: json['complement'] as String?,
    complete: json['complete'] as bool? ?? false,
    shortForm: json['shortForm'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'zipCode': zipCode,
    'street': street,
    'neighborhood': neighborhood,
    'city': city,
    'state': state,
    'streetNumber': streetNumber,
    'complement': complement,
  };

  /// O que o aluno ainda precisa preencher. Nomear os campos é o que permite à
  /// tela dizer o que falta em vez de um "complete seu perfil" que obriga a
  /// pessoa a adivinhar.
  static const camposObrigatorios = <String, String>{
    'zipCode': 'CEP',
    'street': 'Rua',
    'neighborhood': 'Bairro',
    'streetNumber': 'Número',
  };

  List<String> get faltando => [
    if (_vazio(zipCode)) camposObrigatorios['zipCode']!,
    if (_vazio(street)) camposObrigatorios['street']!,
    if (_vazio(neighborhood)) camposObrigatorios['neighborhood']!,
    if (_vazio(streetNumber)) camposObrigatorios['streetNumber']!,
  ];

  static bool _vazio(String? v) => v == null || v.trim().isEmpty;
}
