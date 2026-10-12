import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/route_config_card.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/pagination/page_result.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../lists/widgets/daily_list_section.dart';
import '../../users/models/user_model.dart';
import '../../users/services/user_service.dart';
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
  late bool _admiteSemInstituicao;

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
    _admiteSemInstituicao = widget.route.admitsNoInstitution;
    _reload(mostrarCarregando: true);
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

  Future<void> _reload({bool mostrarCarregando = false}) async {
    if (mostrarCarregando) setState(() => _loading = true);
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
        _students = (results[2] as PageResult<UserModel>).items
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

                const SectionTitle('Configuração da rota'),
                const SizedBox(height: 12),
                RouteConfigCard(
                  route: widget.route,
                  stops: _stops,
                  vehicles: _vehicles,
                  students: _students,
                  admitsNoInstitution: _admiteSemInstituicao,
                  run: _run,
                  onAdmitsNoInstitutionChanged: _mudarAdmissao,
                  onSectionClosed: _reload,
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _mudarAdmissao(bool valor) async {
    try {
      await context.read<RouteProvider>().update(
        widget.route.id,
        _nameCtrl.text.trim(),
        _descCtrl.text.trim(),
        admitsNoInstitution: valor,
      );
      if (mounted) setState(() => _admiteSemInstituicao = valor);
      if (mounted) {
        showSuccessSnackBar(
          context,
          valor
              ? 'A rota passa a aceitar aluno sem instituição'
              : 'A rota volta a exigir instituição',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
      rethrow;
    }
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
}
