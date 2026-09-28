import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../models/profile_update_model.dart';

/// Carteirinha de estudante virtual.
///
/// Mostra só o que serve numa conferência presencial: quem é a pessoa, onde
/// estuda e onde mora. Do endereço, apenas rua, número e bairro — CEP e cidade
/// não identificam ninguém de perto, e esta é uma tela que se aponta pra outra
/// pessoa.
///
/// A validade é o vínculo ativo, não uma data: é exatamente isso que ela
/// atesta. Reusar `users.expiry_date` seria pior que inútil — aquela coluna é
/// o `isAccountNonExpired()` do Spring Security, e preenchê-la tiraria o login
/// do aluno no dia em que a carteirinha vencesse.
class StudentCardScreen extends StatelessWidget {
  final Me me;

  /// O aluno está em alguma rota. É a condição de validade.
  final bool hasActiveRoute;

  const StudentCardScreen({
    super.key,
    required this.me,
    required this.hasActiveRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carteirinha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _conteudo(context),
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    // Carteirinha pela metade não serve pra conferência nenhuma, e meia linha
    // de endereço parece dado perdido. Melhor dizer o que falta.
    if (!me.profileCompleteForList) {
      return _Aviso(
        key: const Key('student_card_incomplete'),
        icon: Icons.badge_outlined,
        titulo: 'Complete seu perfil',
        texto:
            'A carteirinha mostra seus dados de cadastro. '
            'Falta: ${me.faltandoEmPortugues.join(', ')}.',
      );
    }
    if (!hasActiveRoute) {
      return _Aviso(
        key: const Key('student_card_no_route'),
        icon: Icons.directions_bus_outlined,
        titulo: 'Sem vínculo ativo',
        texto:
            'A carteirinha vale enquanto você estiver em uma rota. '
            'Entre em uma com o código que a administração passou.',
      );
    }
    return _Cartao(me: me);
  }
}

class _Cartao extends StatelessWidget {
  final Me me;

  const _Cartao({required this.me});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Column(
      key: const Key('student_card_body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(
                    text: me.fullName.isNotEmpty
                        ? me.fullName[0].toUpperCase()
                        : '?',
                    radius: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estudante', style: texto.bodySmall),
                        const SizedBox(height: 2),
                        Text(me.fullName, style: texto.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              // Rótulo órfão sobre um valor vazio parece campo que não
              // carregou: cada bloco só existe se tiver o que mostrar.
              if (me.institution case final nome?)
                _Campo(rotulo: 'Instituição', valor: nome),
              if (me.course case final curso? when curso.trim().isNotEmpty)
                _Campo(rotulo: 'Curso', valor: curso),
              _Campo(rotulo: 'Endereço', valor: me.address.shortForm),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Não é documento oficial nem prova de matrícula. '
                'Mostra o que você declarou no cadastro.',
                style: texto.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _Campo({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String texto;

  const _Aviso({
    super.key,
    required this.icon,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: EmptyState(icon: icon, title: titulo, subtitle: texto),
    );
  }
}
