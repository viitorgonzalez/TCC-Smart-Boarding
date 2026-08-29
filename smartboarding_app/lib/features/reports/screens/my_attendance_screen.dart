import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../../lists/services/list_service.dart';
import '../models/attendance_model.dart';

/// Log de comparecimento do aluno — o relatório operacional é do admin.
class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  late Future<List<AttendanceDay>> _future;

  static const _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  static const _weekdays = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];

  @override
  void initState() {
    super.initState();
    _future = ListService().getMyAttendance();
  }

  Future<void> _reload() async {
    setState(() => _future = ListService().getMyAttendance());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas idas')),
      body: SafeArea(
        child: FutureBuilder<List<AttendanceDay>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(AppException.fromError(snapshot.error!)),
              );
            }
            final days = snapshot.data ?? const <AttendanceDay>[];
            if (days.isEmpty) {
              return const EmptyState(
                icon: Icons.event_available_outlined,
                title: 'Você ainda não entrou em nenhuma lista',
              );
            }
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _Summary(total: days.length),
                  const SizedBox(height: 24),
                  ..._byMonth(days),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Preserva a ordem do backend: do mais recente pro mais antigo.
  List<Widget> _byMonth(List<AttendanceDay> days) {
    final widgets = <Widget>[];
    String? currentKey;

    for (final day in days) {
      final parsed = DateTime.tryParse(day.date);
      if (parsed == null) continue;
      final key = '${parsed.year}-${parsed.month}';
      if (key != currentKey) {
        currentKey = key;
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 20));
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_months[parsed.month - 1]} de ${parsed.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _DayTile(
            day: day,
            date: parsed,
            weekday: _weekdays[parsed.weekday - 1],
          ),
        ),
      );
    }
    return widgets;
  }
}

class _Summary extends StatelessWidget {
  final int total;
  const _Summary({required this.total});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.positiveBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.positiveFg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total ${total == 1 ? 'ida' : 'idas'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'nos últimos 6 meses',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final AttendanceDay day;
  final DateTime date;
  final String weekday;

  const _DayTile({
    required this.day,
    required this.date,
    required this.weekday,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}'.padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  day.routeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TripTypeChip(tripType: day.tripType, iconSize: 15),
        ],
      ),
    );
  }
}
