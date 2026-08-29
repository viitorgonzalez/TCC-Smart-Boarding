import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/scheduled_notification_model.dart';
import '../services/notification_service.dart';

const _frequencyLabels = {
  'DAILY': 'Todo dia',
  'WEEKDAYS': 'Dias úteis',
  'WEEKLY': 'Semanal',
};

const _weekdayLabels = {
  1: 'segunda',
  2: 'terça',
  3: 'quarta',
  4: 'quinta',
  5: 'sexta',
  6: 'sábado',
  7: 'domingo',
};

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
    final draft = await showModalBottomSheet<_ScheduledDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _ScheduledNotificationForm(),
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
    final when = _frequencyLabels[n.frequency] ?? n.frequency;
    final day = n.frequency == 'WEEKLY' && n.dayOfWeek != null
        ? ' (${_weekdayLabels[n.dayOfWeek]})'
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

class _ScheduledDraft {
  final String title;
  final String body;
  final String frequency;
  final String sendAt;
  final int dayOfWeek;
  final int? durationHours;

  const _ScheduledDraft({
    required this.title,
    required this.body,
    required this.frequency,
    required this.sendAt,
    required this.dayOfWeek,
    this.durationHours,
  });
}

class _ScheduledNotificationForm extends StatefulWidget {
  const _ScheduledNotificationForm();

  @override
  State<_ScheduledNotificationForm> createState() =>
      _ScheduledNotificationFormState();
}

class _ScheduledNotificationFormState
    extends State<_ScheduledNotificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _frequency = 'WEEKDAYS';
  int _dayOfWeek = 1;
  TimeOfDay _sendAt = const TimeOfDay(hour: 7, minute: 0);
  int? _durationHours = 12;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ScheduledDraft(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        frequency: _frequency,
        sendAt:
            '${_sendAt.hour.toString().padLeft(2, '0')}:'
            '${_sendAt.minute.toString().padLeft(2, '0')}:00',
        dayOfWeek: _dayOfWeek,
        durationHours: _durationHours,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sem isto o teclado cobre os últimos campos do formulário.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo aviso automático',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'O sistema envia sozinho pra todos da rota, no horário escolhido.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Mensagem'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe a mensagem'
                    : null,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Frequência'),
                items: [
                  for (final e in _frequencyLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              if (_frequency == 'WEEKLY') ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _dayOfWeek,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  items: [
                    for (final e in _weekdayLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _dayOfWeek = v!),
                ),
              ],
              const SizedBox(height: 14),
              _SendAtField(
                value: _sendAt,
                onPicked: (v) => setState(() => _sendAt = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int?>(
                initialValue: _durationHours,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Fica visível por',
                ),
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 horas')),
                  DropdownMenuItem(value: 12, child: Text('12 horas')),
                  DropdownMenuItem(value: 24, child: Text('1 dia')),
                  DropdownMenuItem(value: null, child: Text('Sem prazo')),
                ],
                onChanged: (v) => setState(() => _durationHours = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Criar aviso'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendAtField extends StatelessWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onPicked;

  const _SendAtField({required this.value, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Enviar às'),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: AppColors.deepTeal),
            const SizedBox(width: 12),
            Text(
              value.format(context),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
