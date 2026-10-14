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
import 'student_list_card_parts.dart';

class StudentListCard extends StatelessWidget {
  final ListWithEnrollment item;
  final void Function(String tripType) onEnter;
  final VoidCallback onLeave;

  final List<String> missingProfile;

  final VoidCallback? onFixProfile;

  final VoidCallback? onFollowTrip;

  const StudentListCard({
    super.key,
    required this.item,
    required this.onEnter,
    required this.onLeave,
    this.missingProfile = const [],
    this.onFixProfile,
    this.onFollowTrip,
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

          if (list.myTripTime case final tempo?) ...[
            const SizedBox(height: 14),
            TempoDeViagem(tempo: tempo),
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
          if (list.tripInProgress && onFollowTrip != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton.tonalIcon(
                key: const Key('student_follow_trip'),
                onPressed: onFollowTrip,
                icon: const Icon(Icons.directions_bus_filled_outlined),
                label: const Text('Acompanhar trajeto'),
              ),
            ),
          ],

          if (acceptingChanges) ...[
            if (hasCloseTime) ...[
              const SizedBox(height: 18),
              CloseCountdown(closeTime: list.closeTime),
            ],
            const SizedBox(height: 18),
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
              ProfileWarning(missing: missingProfile, onFix: onFixProfile)
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
