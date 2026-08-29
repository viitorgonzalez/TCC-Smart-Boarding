import 'package:flutter/material.dart';
import 'app_card.dart';

/// Cartão de carregamento com a mesma moldura dos cartões de conteúdo, pra a
/// seção não mudar de forma quando os dados chegam.
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) => const AppCard(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(),
      ),
    ),
  );
}
