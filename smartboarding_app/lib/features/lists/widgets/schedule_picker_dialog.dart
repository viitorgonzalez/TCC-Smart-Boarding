import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Escolha da janela da lista. Fora da seção porque mudar horário é operação
/// à parte: pede confirmação e avisa a rota.
class SchedulePickerDialog extends StatefulWidget {
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  const SchedulePickerDialog({
    super.key,
    required this.openTime,
    required this.closeTime,
  });

  @override
  State<SchedulePickerDialog> createState() => SchedulePickerDialogState();
}

class SchedulePickerDialogState extends State<SchedulePickerDialog> {
  late TimeOfDay _open = widget.openTime;
  late TimeOfDay _close = widget.closeTime;

  bool get _valid =>
      _open.hour * 60 + _open.minute < _close.hour * 60 + _close.minute;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Horário da lista'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TimeRow(
            label: 'Abre às',
            icon: Icons.lock_open_outlined,
            value: _open,
            onPicked: (v) => setState(() => _open = v),
          ),
          const SizedBox(height: 8),
          TimeRow(
            label: 'Fecha às',
            icon: Icons.lock_outline,
            value: _close,
            onPicked: (v) => setState(() => _close = v),
          ),
          if (!_valid) ...[
            const SizedBox(height: 12),
            Text(
              'A lista precisa abrir antes de fechar.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(context, (open: _open, close: _close))
              : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class TimeRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onPicked;

  const TimeRow({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onPicked,
  });

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.stroke),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.deepTeal),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
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
