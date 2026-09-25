import 'package:flutter/material.dart';

/// Lista que pede mais ao se aproximar do fim.
///
/// Sem numeração de página: pra quem usa continua sendo uma lista só, que
/// simplesmente não acaba enquanto houver o que trazer. O ganho é não baixar a
/// base inteira pra mostrar os primeiros dez nomes.
class InfiniteList extends StatelessWidget {
  final List<Widget> children;

  /// Ainda há o que trazer. Falso esconde o rodapé de carregamento — deixá-lo
  /// girando no fim de uma lista completa sugere que travou.
  final bool hasMore;

  /// Chamado ao chegar perto do fim. Precisa ser barato de repetir: a rolagem
  /// dispara várias vezes, e quem implementa é que guarda o "já estou
  /// buscando".
  final VoidCallback onLoadMore;

  final EdgeInsetsGeometry padding;

  const InfiniteList({
    super.key,
    required this.children,
    required this.hasMore,
    required this.onLoadMore,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 96),
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // 400px antes do fim: pedir só ao encostar deixaria o usuário olhando
        // uma barra de carregamento a cada página.
        if (hasMore && n.metrics.extentAfter < 400) onLoadMore();
        return false;
      },
      child: ListView(
        padding: padding,
        children: [
          ...children,
          if (hasMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
