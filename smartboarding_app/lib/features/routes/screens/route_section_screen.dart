import 'package:flutter/material.dart';

/// Moldura de uma seção da rota aberta em tela própria.
///
/// O detalhe da rota empilhava sete blocos num scroll só, e o que era operação
/// do dia ficava do mesmo tamanho do que se mexe uma vez por semestre. Cada
/// seção secundária passou a ter a própria tela, e esta é a moldura comum.
class RouteSectionScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const RouteSectionScreen({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(20), children: [child]),
  );
}
