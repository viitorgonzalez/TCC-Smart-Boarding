import 'package:flutter/material.dart';
import '../../../core/utils/date_format.dart';
import '../models/registration_request_model.dart';
import '../widgets/registration_actions.dart';

/// A lista de pendentes não cabe todos os dados do pedido, e aprovar sem ver o
/// que o aluno enviou é decidir no escuro — esta tela é a conferência.
class RegistrationDetailScreen extends StatelessWidget {
  final RegistrationRequestModel request;
  const RegistrationDetailScreen({super.key, required this.request});

  Future<void> _act(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final acted = await action();
    if (acted && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitação de cadastro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Field(label: 'Nome completo', value: request.fullName),
            _Field(label: 'E-mail', value: request.email),
            _Field(label: 'Instituição', value: request.institutionName),
            _Field(label: 'Curso', value: request.course),
            _Field(label: 'Telefone', value: request.phone),
            _Field(label: 'Endereço', value: request.address),
            _Field(
              label: 'Data de nascimento',
              value: request.birthDate == null
                  ? null
                  : formatDate(request.birthDate),
            ),
            _Field(
              label: 'Enviado em',
              value: formatDateTime(request.createdAt),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Negar'),
                  onPressed: () =>
                      _act(context, () => promptReject(context, request.id)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aprovar'),
                  onPressed: () =>
                      _act(context, () => confirmApprove(context, request.id)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? value;
  const _Field({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            filled ? value! : 'Não informado',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: filled ? null : theme.colorScheme.onSurfaceVariant,
              fontStyle: filled ? null : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
