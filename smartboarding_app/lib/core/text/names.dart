/// O primeiro nome de alguém.
///
/// O cabeçalho é uma saudação, não um documento: "Vítor Silva Pastor Gonzalez"
/// ocupa duas linhas e empurra as ações pra fora. A pessoa se chama Vítor.
String primeiroNome(String? completo, {String fallback = ''}) {
  final partes = (completo ?? '').split(' ').where((p) => p.isNotEmpty);
  return partes.isEmpty ? fallback : partes.first;
}
