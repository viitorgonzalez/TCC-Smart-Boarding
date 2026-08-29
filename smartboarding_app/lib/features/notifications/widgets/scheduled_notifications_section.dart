import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/scheduled_notification_model.dart';
import '../services/notification_service.dart';
import 'scheduled_notification_form.dart';

/// Avisos que o backend dispara sozinho para quem está na rota.
class ScheduledNotificationsSection extends StatefulWidget {
  final String routeId;
  const ScheduledNotificationsSection({super.key, required this.routeId});

  @override
  State<ScheduledNotificationsSection> createState() =>
      _ScheduledNotificationsSectionState();
}

class _ScheduledNotificationsSectionState
    extends State<ScheduledNotificationsSection> {
  final _service = NotificationService();
  List<ScheduledNotificationModel> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getScheduled(widget.routeId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted) showSuccessSnackBar(context, success);
      await _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<void> _create() async {
    // Bottom sheet em vez de AlertDialog: são seis campos e um teclado —
    // o diálogo estourava a altura disponível.
    final draft = await showModalBottomSheet<ScheduledDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const ScheduledNotificationForm(),
    );
    if (draft == null) return;
    await _run(
      () => _service.createScheduled(
        routeId: widget.routeId,
        title: draft.title,
        body: draft.body,
        frequency: draft.frequency,
        sendAt: draft.sendAt,
        dayOfWeek: draft.frequency == 'WEEKLY' ? draft.dayOfWeek : null,
        durationHours: draft.durationHours,
      ),
      'Aviso automático criado',
    );
  }

  String _schedule(ScheduledNotificationModel n) {
    final when = frequencyLabels[n.frequency] ?? n.frequency;
    final day = n.frequency == 'WEEKLY' && n.dayOfWeek != null
        ? ' (${weekdayLabels[n.dayOfWeek]})'
        : '';
    return '$when$day às ${formatCloseTime(n.sendAt)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_items.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhum aviso automático',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Crie um pra lembrar a rota sem ter que enviar na mão todo dia.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        for (final n in _items) ...[
          _ScheduledTile(
            notification: n,
            schedule: _schedule(n),
            onToggle: (v) => _run(
              () => _service.toggleScheduled(n.id, v),
              v ? 'Aviso reativado' : 'Aviso pausado',
            ),
            onDelete: () =>
                _run(() => _service.deleteScheduled(n.id), 'Aviso removido'),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 2),
        OutlinedButton.icon(
          onPressed: _create,
          icon: const Icon(Icons.add_alert_outlined, size: 18),
          label: const Text('Novo aviso automático'),
        ),
      ],
    );
  }
}

class _ScheduledTile extends StatelessWidget {
  final ScheduledNotificationModel notification;
  final String schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ScheduledTile({
    required this.notification,
    required this.schedule,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = notification.active;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            active ? Icons.alarm_on : Icons.alarm_off,
            color: active ? AppColors.deepTeal : AppColors.textSecondary,
          ),
          const SizedBox(width: 14),
          // Expanded é o que impede o texto longo de empurrar as ações pra fora
          // do card — o motivo do estouro anterior.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  schedule,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (notification.lastSentAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Último envio: ${formatDateTime(notification.lastSentAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(value: active, onChanged: onToggle),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.danger,
                ),
                tooltip: 'Remover aviso',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
