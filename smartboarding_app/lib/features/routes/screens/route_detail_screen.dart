import 'package:flutter/material.dart';
// latlong2 exporta uma classe Path própria, que sombreia a de dart:ui usada
// no desenho do pino.
import 'package:provider/provider.dart';
import '../widgets/route_institutions_card.dart';
import '../widgets/route_stops_editor.dart';
import '../widgets/route_vehicles_card.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../lists/widgets/daily_list_section.dart';
import '../../notifications/widgets/scheduled_notifications_section.dart';
import '../../users/models/user_model.dart';
import '../../users/screens/route_students_screen.dart';
import '../../users/services/user_service.dart';
import '../../users/widgets/role_meta.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/vehicle_model.dart';
import '../providers/route_provider.dart';
import '../services/route_service.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteModel route;
  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final _service = RouteService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  List<StopModel> _stops = const [];
  List<VehicleModel> _vehicles = const [];
  List<UserModel> _students = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.route.name);
    _descCtrl = TextEditingController(text: widget.route.description ?? '');
    _openTime = _asTimeOfDay(widget.route.openTime);
    _closeTime = _asTimeOfDay(widget.route.closeTime);
    _reload();
  }

  static TimeOfDay? _asTimeOfDay(String? raw) {
    final parsed = parseTimeOfDay(raw);
    return parsed == null
        ? null
        : TimeOfDay(hour: parsed.hour, minute: parsed.minute);
  }

  static String? _asApiTime(TimeOfDay? time) => time == null
      ? null
      : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}:00';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getStops(widget.route.id),
        _service.getVehicles(widget.route.id),
        UserService().getUsers(routeId: widget.route.id),
      ]);
      if (!mounted) return;
      setState(() {
        _stops = results[0] as List<StopModel>;
        _vehicles = results[1] as List<VehicleModel>;
        _students = (results[2] as List<UserModel>)
            .where((u) => u.role == 'STUDENT')
            .toList();
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

  Future<void> _saveBasics() async {
    setState(() => _saving = true);
    try {
      await context.read<RouteProvider>().update(
        widget.route.id,
        _nameCtrl.text.trim(),
        _descCtrl.text.trim(),
      );
      if (mounted) showSuccessSnackBar(context, 'Rota atualizada');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.route.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SectionTitle('Dados da rota'),
                const SizedBox(height: 12),
                _basics(),
                const SizedBox(height: 24),
                const SectionTitle('Lista de hoje'),
                const SizedBox(height: 12),
                DailyListSection(
                  routeId: widget.route.id,
                  openTime: _asApiTime(_openTime),
                  closeTime: _asApiTime(_closeTime),
                  onScheduleChanged: (schedule) => setState(() {
                    _openTime = _asTimeOfDay(schedule.openTime);
                    _closeTime = _asTimeOfDay(schedule.closeTime);
                  }),
                ),
                const SizedBox(height: 24),
                const SectionTitle('Avisos automáticos'),
                const SizedBox(height: 12),
                ScheduledNotificationsSection(routeId: widget.route.id),
                const SizedBox(height: 24),
                const SectionTitle('Trajeto'),
                const SizedBox(height: 12),
                RouteStopsEditor(
                  routeId: widget.route.id,
                  stops: _stops,
                  run: _run,
                ),
                const SizedBox(height: 24),
                const SectionTitle('Frota'),
                const SizedBox(height: 12),
                RouteVehiclesCard(
                  routeId: widget.route.id,
                  vehicles: _vehicles,
                  run: _run,
                ),
                const SizedBox(height: 24),
                const SectionTitle('Instituições atendidas'),
                const SizedBox(height: 12),
                RouteInstitutionsCard(routeId: widget.route.id),
                const SizedBox(height: 24),
                const SectionTitle('Alunos'),
                const SizedBox(height: 12),
                _studentsCard(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _basics() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome da rota'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _saveBasics,
            child: Text(_saving ? 'Salvando...' : 'Salvar dados da rota'),
          ),
        ],
      ),
    );
  }

  /// Escopado por rota porque a base de usuários cresce sem teto.
  Widget _studentsCard() {
    final preview = sortUsersByName(_students).take(4).toList();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          if (_students.isEmpty)
            const ListTile(
              title: Text('Nenhum aluno nesta rota'),
              subtitle: Text(
                'O aluno chega por convite e escolhe a instituição no cadastro.',
              ),
            ),
          for (final student in preview)
            ListTile(
              leading: InitialsAvatar(
                text: student.fullName.isNotEmpty
                    ? student.fullName[0].toUpperCase()
                    : '?',
              ),
              title: Text(student.fullName),
              subtitle: Text(student.institution ?? student.email),
            ),
          if (_students.isNotEmpty) const Divider(height: 1),
          if (_students.isNotEmpty)
            ListTile(
              leading: const Icon(
                Icons.people_outline,
                color: AppColors.deepTeal,
              ),
              title: Text(
                _students.length == 1
                    ? 'Ver o aluno da rota'
                    : 'Ver todos os ${_students.length} alunos',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteStudentsScreen(
                    routeId: widget.route.id,
                    routeName: widget.route.name,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Já nasce vinculada: instituição sem rota deixa os alunos dela sem lista.
  /// Só mover e inserir esperam um toque no mapa.
  /// O toque no mapa muda de significado conforme o modo ativo.
}
