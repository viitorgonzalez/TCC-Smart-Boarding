import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/loading_card.dart';
import '../../../core/widgets/institution_breakdown.dart';
import '../../../core/widgets/reason_dialog.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../../core/widgets/status_pill.dart';
import '../../routes/services/route_service.dart';
import 'daily_list_schedule_card.dart';
import '../models/daily_list_model.dart';
import '../screens/admin_list_entries_screen.dart';
import '../services/list_service.dart';
import 'schedule_picker_dialog.dart';

/// Lista de hoje da rota, embutida na tela da rota: uma rota tem no máximo uma
/// lista por dia, então não faz sentido gerenciá-las numa tela separada.
class DailyListSection extends StatefulWidget {
  final String routeId;
  final String? openTime;
  final String? closeTime;

  /// A rota é recarregada quando o horário muda — quem exibe precisa saber.
  final ValueChanged<({String openTime, String closeTime})> onScheduleChanged;

  const DailyListSection({
    super.key,
    required this.routeId,
    required this.onScheduleChanged,
    this.openTime,
    this.closeTime,
  });

  @override
  State<DailyListSection> createState() => _DailyListSectionState();
}

class _DailyListSectionState extends State<DailyListSection> {
  final _service = ListService();
  final _routeService = RouteService();
  DailyList? _list;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final lists = await _service.getListsByDate(DateTime.now());
      if (!mounted) return;
      setState(() {
        _list = lists.where((l) => l.routeId == widget.routeId).firstOrNull;
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

  Future<void> _toggleStatus(DailyList list) async {
    final closing = list.isOpen;
    final reason = await showReasonDialog(
      context,
      title: closing ? 'Fechar a lista agora?' : 'Reabrir a lista?',
      message: closing
          ? 'Fora do horário configurado. Todos os alunos da rota recebem um '
                'aviso com o motivo.'
          : 'Os alunos da rota recebem um aviso com o motivo.',
      hint: 'Ex.: ônibus quebrou, sem viagem hoje.',
      confirmLabel: closing ? 'Fechar e avisar' : 'Reabrir e avisar',
    );
    if (reason == null) return;
    await _run(
      () =>
          _service.setListStatus(list.id, closing ? 'CLOSED' : 'OPEN', reason),
      closing
          ? 'Lista fechada e alunos avisados'
          : 'Lista reaberta e alunos avisados',
    );
  }

  Future<void> _editSchedule() async {
    final picked = await showDialog<({TimeOfDay open, TimeOfDay close})>(
      context: context,
      builder: (_) => SchedulePickerDialog(
        openTime:
            _asTimeOfDay(widget.openTime) ??
            const TimeOfDay(hour: 0, minute: 0),
        closeTime:
            _asTimeOfDay(widget.closeTime) ??
            const TimeOfDay(hour: 16, minute: 0),
      ),
    );
    if (picked == null || !mounted) return;

    final reason = await showReasonDialog(
      context,
      title: 'Mudar o horário da lista?',
      message:
          'A lista passa a abrir às ${picked.open.format(context)} e fechar às '
          '${picked.close.format(context)}. Todos os alunos da rota são avisados.',
      hint: 'Ex.: horário de aula mudou neste semestre.',
      confirmLabel: 'Salvar e avisar',
    );
    if (reason == null) return;

    final open = _asApiTime(picked.open);
    final close = _asApiTime(picked.close);
    await _run(() async {
      await _routeService.updateSchedule(
        widget.routeId,
        openTime: open,
        closeTime: close,
        reason: reason,
      );
      widget.onScheduleChanged((openTime: open, closeTime: close));
    }, 'Horário atualizado e alunos avisados');
  }

  Future<void> _delete(DailyList list) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Apagar a lista de hoje?',
      message:
          'As inscrições vão junto. Só funciona enquanto a lista não tiver '
          'relatório gerado.',
      confirmLabel: 'Apagar',
    );
    if (!confirmed) return;
    await _run(() => _service.deleteList(list.id), 'Lista apagada');
  }

  static TimeOfDay? _asTimeOfDay(String? raw) {
    final parsed = parseTimeOfDay(raw);
    return parsed == null
        ? null
        : TimeOfDay(hour: parsed.hour, minute: parsed.minute);
  }

  static String _asApiTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DailyListScheduleCard(
          openTime: widget.openTime,
          closeTime: widget.closeTime,
          onEdit: _editSchedule,
        ),
        const SizedBox(height: 12),
        if (_loading) const LoadingCard() else _listCard(),
      ],
    );
  }

  Widget _listCard() {
    final list = _list;
    if (list == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ainda não há lista para hoje.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'O agendador cria no horário de abertura — ou crie agora.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _run(
                () => _service.createList(widget.routeId, DateTime.now()),
                'Lista criada',
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Criar lista de hoje'),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDate(list.date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${list.totalEntries} inscrito(s)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
          if (list.entriesByInstitution.isNotEmpty) ...[
            const SizedBox(height: 16),
            InstitutionBreakdown(
              counts: {
                for (final e in list.entriesByInstitution) e.name: e.count,
              },
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminListEntriesScreen(list: list),
              ),
            ).then((_) => _reload()),
            icon: const Icon(Icons.people_alt_outlined, size: 18),
            label: const Text('Ver inscritos'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _toggleStatus(list),
                  icon: Icon(
                    list.isOpen ? Icons.lock_outline : Icons.lock_open_outlined,
                    size: 18,
                  ),
                  label: Text(list.isOpen ? 'Fechar agora' : 'Reabrir'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                onPressed: () => _delete(list),
                tooltip: 'Apagar lista',
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.stroke),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
