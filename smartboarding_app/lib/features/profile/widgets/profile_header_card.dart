import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/initials_avatar.dart';

/// Quem está logado, no topo do perfil.
class ProfileHeaderCard extends StatelessWidget {
  final String nome;
  final String email;

  const ProfileHeaderCard({super.key, required this.nome, required this.email});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          InitialsAvatar(text: nome.isNotEmpty ? nome[0].toUpperCase() : '?'),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O estado da última solicitação de alteração.
///
/// Dois cards e não um: "em análise" e "recusado" são momentos diferentes e
/// pedem ações diferentes do aluno — esperar num, corrigir no outro.
class ProfileRequestStatus extends StatelessWidget {
  final String? emAnalise;
  final String? motivoDaRecusa;

  const ProfileRequestStatus({super.key, this.emAnalise, this.motivoDaRecusa});

  @override
  Widget build(BuildContext context) {
    if (emAnalise case final mudancas?) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.deepTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solicitação em análise',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mudancas,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pedido recusado: '
              '${motivoDaRecusa ?? "sem motivo informado"}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalho pra carteirinha. Só pro aluno: quem administra não tem vínculo de
/// estudante a atestar.
class StudentCardLink extends StatelessWidget {
  final VoidCallback onAbrir;

  const StudentCardLink({super.key, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        key: const Key('profile_open_student_card'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.badge_outlined, color: AppColors.deepTeal),
        title: const Text('Carteirinha'),
        subtitle: const Text(
          'Seus dados de estudante, pra mostrar na conferência',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onAbrir,
      ),
    );
  }
}
