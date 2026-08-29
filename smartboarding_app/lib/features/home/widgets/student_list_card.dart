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

  const StudentListCard({
    super.key,
    required this.item,
    required this.onEnter,
    required this.onLeave,
  });

  Future<void> _pickAndEnter(BuildContext context, {String? current}) async {
    final chosen = await showTripTypePicker(context, current: current);
    if (chosen != null) onEnter(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final list = item.list;
    // A lista só vira CLOSED na próxima varredura (até 5 min depois do horário).
    // Sem olhar o relógio, o botão de entrar fica vivo nessa janela e o toque
    // morre em 400 LIST_CLOSED. Horário desconhecido não é horário vencido.
    final hasCloseTime = parseTimeOfDay(list.closeTime) != null;
    final acceptingChanges =
        list.isOpen &&
        (!hasCloseTime || timeUntilListClose(list.closeTime) != null);

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
                  label: 'Fecha às',
                  value: hasCloseTime ? formatCloseTime(list.closeTime) : '—',
                  valueColor: AppColors.deepTeal,
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
          if (list.proposedVehicles.isNotEmpty ||
              list.capacityShortfall > 0) ...[
            const SizedBox(height: 14),
            ProposedVehicle(
              vehicles: list.proposedVehicles,
              shortfall: list.capacityShortfall,
            ),
          ] else if (list.vehicles.isNotEmpty) ...[
            const SizedBox(height: 14),
            // Antes do fechamento a frota é só informação: o veículo definitivo
            // depende do total final de confirmados (RN16).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list.vehicles
                  .map(
                    (v) => Chip(
                      avatar: const Icon(
                        Icons.directions_bus_outlined,
                        size: 16,
                        color: AppColors.deepTeal,
                      ),
                      label: Text('${v.label} · ${v.capacity} lugares'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.background,
                      side: const BorderSide(color: AppColors.stroke),
                    ),
                  )
                  .toList(),
            ),
          ],
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
            item.isEnrolled
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: onLeave,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Sair da lista'),
                  )
                : FilledButton.icon(
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

/// Resultado da RN16: o transporte definido pelo total de confirmados.
