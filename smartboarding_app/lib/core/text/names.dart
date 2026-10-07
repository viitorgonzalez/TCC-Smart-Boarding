String primeiroNome(String? completo, {String fallback = ''}) {
  final partes = (completo ?? '').split(' ').where((p) => p.isNotEmpty);
  return partes.isEmpty ? fallback : partes.first;
}
