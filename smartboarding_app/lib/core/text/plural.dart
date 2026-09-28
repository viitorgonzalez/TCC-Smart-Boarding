/// Contagem com o substantivo já flexionado.
///
/// Existe porque "0 inscrito(s) hoje" e "7 parada(s)" espalhados pelas telas
/// eram atalho de programador aparecendo pro usuário. O parêntese não é
/// português; é a ausência de uma decisão sobre o texto.
///
/// [zero] troca a frase inteira quando não há nenhum, que quase sempre lê
/// melhor: "Ninguém inscrito hoje" em vez de "0 inscritos hoje".
String contagem(
  int quantidade,
  String singular,
  String plural, {
  String? zero,
}) {
  if (quantidade == 0 && zero != null) return zero;
  return '$quantidade ${quantidade == 1 ? singular : plural}';
}
