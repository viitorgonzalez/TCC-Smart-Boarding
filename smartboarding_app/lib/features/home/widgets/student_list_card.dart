import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/institution_breakdown.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../../lists/models/list_with_enrollment.dart';
import 'close_countdown.dart';
import 'list_members_sheet.dart';
import 'trip_type_picker.dart';
import 'route_preview.dart';

class StudentListCard extends StatelessWidget {
  final ListWithEnrollment item;
  final void Function(String tripType) onEnter;
  final VoidCallback onLeave;

  /// O que falta no perfil, já em português. Vazio = pode entrar.
  ///
  /// Chega pronto de fora porque quem decide é o backend: ele é que recusa a
  /// entrada, e refazer a conta aqui daria duas versões da regra.
  final List<String> missingProfile;

  /// Atalho pro perfil. Sem ele o aviso diria o problema e deixaria a pessoa
  /// procurar sozinha onde resolvê-lo.
  final VoidCallback? onFixProfile;

  const StudentListCard({
    super.key,
    required this.item,
    required this.onEnter,
    required this.onLeave,
    this.missingProfile = const [],
    this.onFixProfile,
  });

  Future<void> _pickAndEnter(BuildContext context, {String? current}) async {
    final chosen = await showTripTypePicker(context, current: current);
    if (chosen != null) onEnter(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final list = item.list;
    final hasCloseTime = parseTimeOfDay(list.closeTime) != null;
    final acceptingChanges = list.acceptsChanges;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  list.routeName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              StatusPill(
                label: list.isOpen ? 'ABERTA' : 'FECHADA',
                tone: list.isOpen
                    ? StatusPillTone.positive
                    : StatusPillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            formatDate(list.date),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      showListMembers(context, list.id, list.routeName),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatBlock(
                        label: 'Confirmados',
                        value: '${list.totalEntries}',
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 22, left: 4),
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StatBlock(
                  // Ja fechada, "fecha as" descreve um futuro que nao existe.
                  label: acceptingChanges ? 'Fecha às' : 'Fechou às',
                  value: hasCloseTime ? formatCloseTime(list.closeTime) : '—',
                  valueColor: acceptingChanges
                      ? AppColors.deepTeal
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (list.entriesByInstitution.isNotEmpty) ...[
            const SizedBox(height: 14),
            InstitutionBreakdown(
              compact: true,
              counts: {
                for (final i in list.entriesByInstitution) i.name: i.count,
              },
            ),
          ],
          // Sempre o veiculo recomendado pro total atual, nunca a frota
          // inteira: com "Onibus (45)" e "Van (15)" lado a lado o aluno tinha
          // que adivinhar em qual dos dois ele ia.
          const SizedBox(height: 14),
          ProposedVehicle(
            vehicles: list.proposedVehicles,
            shortfall: list.capacityShortfall,
            definido: !list.acceptsChanges,
          ),
          if (list.stops.any((s) => s.hasCoordinates)) ...[
            const SizedBox(height: 18),
            RoutePreview(list: list),
          ],
          if (item.isEnrolled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Você está na lista',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TripTypeChip(tripType: item.tripType, iconSize: 18),
                if (acceptingChanges)
                  IconButton(
                    tooltip: 'Trocar direção',
                    onPressed: () =>
                        _pickAndEnter(context, current: item.tripType),
                    icon: const Icon(Icons.edit, size: 18),
                  ),
              ],
            ),
          ],
          if (acceptingChanges) ...[
            if (hasCloseTime) ...[
              const SizedBox(height: 18),
              CloseCountdown(closeTime: list.closeTime),
            ],
            const SizedBox(height: 18),
            // Quem já está na lista entrou quando era permitido: o aviso de
            // perfil não vale pra ele, e esconder o "Sair" por um campo em
            // branco o prenderia numa viagem que ele não vai fazer.
            if (item.isEnrolled)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                onPressed: onLeave,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Sair da lista'),
              )
            else if (missingProfile.isNotEmpty)
              _ProfileWarning(
                missing: missingProfile,
                onFix: onFixProfile,
              )
            else
              FilledButton.icon(
                onPressed: () => _pickAndEnter(context),
                icon: const Icon(Icons.login),
                label: const Text('Entrar na lista'),
              ),
          ],
        ],
      ),
    );
  }
}

/// O bloqueio, sinalizado antes do toque.
///
/// Aparece no lugar do botão e não como erro depois dele: descobrir a parede
/// esbarrando nela é o que essa tela existe pra evitar.
class _ProfileWarning extends StatelessWidget {
  final List<String> missing;
  final VoidCallback? onFix;

  const _ProfileWarning({required this.missing, this.onFix});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('list_profile_warning'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete seu perfil para entrar na lista.',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              'Falta: ${missing.join(', ')}.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: const Key('list_profile_fix_button'),
              onPressed: onFix,
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Completar perfil'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resultado da RN16: o transporte definido pelo total de confirmados.
