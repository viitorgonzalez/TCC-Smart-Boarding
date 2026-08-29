import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/institution_breakdown.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../../lists/models/daily_list_model.dart';
import '../../lists/models/list_with_enrollment.dart';
import '../../routes/screens/route_stops_screen.dart';
import '../../routes/widgets/route_map.dart';
import 'close_countdown.dart';
import 'list_members_sheet.dart';
import 'trip_type_picker.dart';

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
            _ProposedVehicle(
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
            _RoutePreview(list: list),
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
class _ProposedVehicle extends StatelessWidget {
  final List<VehicleSummary> vehicles;
  final int shortfall;

  const _ProposedVehicle({required this.vehicles, required this.shortfall});

  @override
  Widget build(BuildContext context) {
    final insufficient = shortfall > 0;
    final color = insufficient ? AppColors.danger : AppColors.positiveFg;
    final background = insufficient ? AppColors.dangerBg : AppColors.positiveBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insufficient ? Icons.warning_amber : Icons.directions_bus,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                'TRANSPORTE DEFINIDO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            vehicles.isEmpty
                ? 'Nenhum veículo disponível na rota'
                : vehicles
                      .map((v) => '${v.label} (${v.capacity})')
                      .join('  +  '),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          if (insufficient) ...[
            const SizedBox(height: 4),
            Text(
              '$shortfall pessoa(s) sem lugar na frota',
              style: TextStyle(fontSize: 13, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  final DailyList list;
  const _RoutePreview({required this.list});

  @override
  Widget build(BuildContext context) {
    final located = list.stops.where((s) => s.hasCoordinates).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RouteMap(
          compact: true,
          stops: [
            for (final s in located)
              MapStop(
                name: s.name,
                latitude: s.latitude!,
                longitude: s.longitude!,
                sequence: s.sequence,
              ),
          ],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteStopsScreen(
                routeId: list.routeId,
                routeName: list.routeName,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.route_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                located.length < 2
                    ? '${located.length} parada'
                    : '${located.length} paradas · ${located.first.name} → ${located.last.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              'ver mapa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.deepTeal,
            ),
          ],
        ),
      ],
    );
  }
}
