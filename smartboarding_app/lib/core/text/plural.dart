String contagem(
  int quantidade,
  String singular,
  String plural, {
  String? zero,
}) {
  if (quantidade == 0 && zero != null) return zero;
  return '$quantidade ${quantidade == 1 ? singular : plural}';
}
