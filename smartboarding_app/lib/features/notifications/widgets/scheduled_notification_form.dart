import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Rótulos compartilhados com a seção que lista os avisos.
const frequencyLabels = {
  'DAILY': 'Todo dia',
  'WEEKDAYS': 'Dias úteis',
  'WEEKLY': 'Semanal',
};

const weekdayLabels = {
  1: 'segunda',
  2: 'terça',
  3: 'quarta',
  4: 'quinta',
  5: 'sexta',
  6: 'sábado',
  7: 'domingo',
};

/// Formulário do aviso recorrente. Em arquivo próprio porque a seção só lista
/// e alterna — criar é outro assunto, com seis campos e teclado.
class ScheduledDraft {
  final String title;
  final String body;
  final String frequency;
  final String sendAt;
  final int dayOfWeek;
  final int? durationHours;

  const ScheduledDraft({
    required this.title,
    required this.body,
    required this.frequency,
    required this.sendAt,
    required this.dayOfWeek,
    this.durationHours,
  });
}

class ScheduledNotificationForm extends StatefulWidget {
  const ScheduledNotificationForm({super.key});

  @override
  State<ScheduledNotificationForm> createState() =>
      ScheduledNotificationFormState();
}

class ScheduledNotificationFormState extends State<ScheduledNotificationForm> {
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
      ScheduledDraft(
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
                  for (final e in frequencyLabels.entries)
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
                    for (final e in weekdayLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _dayOfWeek = v!),
                ),
              ],
              const SizedBox(height: 14),
              SendAtField(
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

class SendAtField extends StatelessWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onPicked;

  const SendAtField({super.key, required this.value, required this.onPicked});

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
