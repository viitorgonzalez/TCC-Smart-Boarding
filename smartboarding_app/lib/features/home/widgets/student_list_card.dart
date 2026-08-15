import 'package:flutter/material.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../../lists/models/list_with_enrollment.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    list.routeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusPill(
                  label: list.isOpen ? 'Aberta' : 'Fechada',
                  tone: list.isOpen
                      ? StatusPillTone.positive
                      : StatusPillTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${list.totalEntries} inscrito(s) · ${formatDate(list.date)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    showListMembers(context, list.id, list.routeName),
                icon: const Icon(Icons.people_outline, size: 18),
                label: const Text('Ver quem está na lista'),
              ),
            ),
            if (item.isEnrolled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Você está na lista',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Direção atual + trocar (enquanto a lista estiver aberta)
              Row(
                children: [
                  TripTypeChip(tripType: item.tripType, iconSize: 18),
                  if (list.isOpen)
                    TextButton.icon(
                      onPressed: () =>
                          _pickAndEnter(context, current: item.tripType),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Trocar direção'),
                    ),
                ],
              ),
            ],
            if (list.isOpen) ...[
              const SizedBox(height: 12),
              const CloseCountdown(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: item.isEnrolled
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                        ),
                        onPressed: onLeave,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Sair da lista'),
                      )
                    : FilledButton.icon(
                        onPressed: () => _pickAndEnter(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Entrar na lista'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
