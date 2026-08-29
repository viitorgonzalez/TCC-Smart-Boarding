import 'package:flutter/material.dart';
// latlong2 exporta uma classe Path própria, que sombreia a de dart:ui usada
// no desenho do pino.
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../lists/widgets/daily_list_section.dart';
import '../../notifications/widgets/scheduled_notifications_section.dart';
import '../../registration/models/institution_model.dart';
import '../../registration/services/institution_service.dart';
import '../../users/models/user_model.dart';
import '../../users/screens/route_students_screen.dart';
import '../../users/services/user_service.dart';
import '../../users/widgets/role_meta.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/vehicle_model.dart';
import '../providers/route_provider.dart';
import '../widgets/route_map.dart';
import '../services/route_service.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteModel route;
  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final _service = RouteService();
  final _institutionService = InstitutionService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  List<StopModel> _stops = const [];
  List<VehicleModel> _vehicles = const [];
  List<InstitutionModel> _institutions = const [];
  List<UserModel> _students = const [];
  bool _loading = true;
  bool _saving = false;

  /// Parada sendo reposicionada, ou depois da qual a próxima será inserida.
  StopModel? _pendingStop;
  _StopAction? _pendingAction;

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
        _institutionService.getInstitutions(),
        UserService().getUsers(routeId: widget.route.id),
      ]);
      if (!mounted) return;
      setState(() {
        _stops = results[0] as List<StopModel>;
        _vehicles = results[1] as List<VehicleModel>;
        _institutions = results[2] as List<InstitutionModel>;
        _students = (results[3] as List<UserModel>)
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
                RouteMap(
                  stops: [
                    for (final s in _stops)
                      if (s.hasCoordinates)
                        MapStop(
                          id: s.id,
                          name: s.name,
                          latitude: s.latitude!,
                          longitude: s.longitude!,
                          sequence: s.sequence,
                        ),
                  ],
                  onTapPoint: _onMapPoint,
                  onTapStop: _onTapStop,
                  modeLabel: _modeLabel,
                  onCancelMode: _pendingAction == null
                      ? null
                      : () => setState(() {
                          _pendingAction = null;
                          _pendingStop = null;
                        }),
                ),
                const SizedBox(height: 12),
                _stopsList(),
                const SizedBox(height: 24),
                const SectionTitle('Frota'),
                const SizedBox(height: 12),
                _vehiclesCard(),
                const SizedBox(height: 24),
                const SectionTitle('Instituições atendidas'),
                const SizedBox(height: 12),
                _institutionsCard(),
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

  Widget _stopsList() {
    if (_stops.isEmpty) {
      return const AppCard(
        child: Text('Nenhuma parada. Toque no mapa para adicionar.'),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final stop in _stops)
            ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.ashGrey,
                child: Text(
                  '${stop.sequence}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkSlate,
                  ),
                ),
              ),
              title: Text(stop.name),
              subtitle: stop.hasCoordinates
                  ? Text(
                      '${stop.latitude!.toStringAsFixed(4)}, '
                      '${stop.longitude!.toStringAsFixed(4)}',
                    )
                  : const Text('sem coordenada'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _run(
                  () => _service.deleteStop(widget.route.id, stop.id),
                  'Parada removida',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vehiclesCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final vehicle in _vehicles)
            ListTile(
              leading: const Icon(
                Icons.directions_bus_outlined,
                color: AppColors.deepTeal,
              ),
              title: Text(vehicle.label),
              subtitle: Text('${vehicle.capacity} lugares'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _run(
                  () => _service.deleteVehicle(widget.route.id, vehicle.id),
                  'Veículo removido',
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.add, color: AppColors.deepTeal),
            title: const Text('Adicionar veículo'),
            onTap: _promptAddVehicle,
          ),
        ],
      ),
    );
  }

  Widget _institutionsCard() {
    final linked = _institutions
        .where((i) => i.routeId == widget.route.id)
        .toList();
    final others = _institutions
        .where((i) => i.routeId != widget.route.id)
        .toList();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          if (linked.isEmpty)
            const ListTile(
              title: Text('Nenhuma instituição atendida'),
              subtitle: Text(
                'Alunos só veem esta rota se a instituição deles apontar pra ela.',
              ),
            ),
          for (final institution in linked)
            ListTile(
              leading: const Icon(Icons.school, color: AppColors.deepTeal),
              title: Text(institution.name),
              subtitle: institution.address == null
                  ? null
                  : Text(
                      institution.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => _institutionAction(v, institution),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'unlink', child: Text('Desvincular')),
                  PopupMenuItem(value: 'delete', child: Text('Remover')),
                ],
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add, color: AppColors.deepTeal),
            title: const Text('Cadastrar instituição nesta rota'),
            onTap: _promptCreateInstitution,
          ),
          if (others.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.deepTeal),
              title: const Text('Vincular uma já cadastrada'),
              onTap: () => _promptLinkInstitution(others),
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

  Future<void> _institutionAction(String action, InstitutionModel i) async {
    switch (action) {
      case 'edit':
        final data = await _promptInstitutionForm(
          title: 'Editar instituição',
          name: i.name,
          address: i.address,
        );
        if (data == null) return;
        await _run(
          () => _institutionService.updateInstitution(
            i.id,
            name: data.$1,
            address: data.$2,
          ),
          'Instituição atualizada',
        );
      case 'unlink':
        await _run(
          () => _institutionService.linkRoute(i.id, null),
          'Instituição desvinculada',
        );
      case 'delete':
        // O backend recusa se houver aluno vinculado — a rota dele sai daqui.
        await _run(
          () => _institutionService.deleteInstitution(i.id),
          'Instituição removida',
        );
    }
  }

  /// Já nasce vinculada: instituição sem rota deixa os alunos dela sem lista.
  Future<void> _promptCreateInstitution() async {
    final data = await _promptInstitutionForm(title: 'Nova instituição');
    if (data == null) return;
    await _run(
      () => _institutionService.createInstitution(
        data.$1,
        address: data.$2,
        routeId: widget.route.id,
      ),
      'Instituição cadastrada nesta rota',
    );
  }

  Future<(String, String)?> _promptInstitutionForm({
    required String title,
    String? name,
    String? address,
  }) async {
    final nameCtrl = TextEditingController(text: name ?? '');
    final addressCtrl = TextEditingController(text: address ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return null;
    return (nameCtrl.text.trim(), addressCtrl.text.trim());
  }

  /// Só mover e inserir esperam um toque no mapa.
  String? get _modeLabel => switch (_pendingAction) {
    _StopAction.move => 'Toque no novo local de "${_pendingStop!.name}"',
    _StopAction.insertAfter =>
      'Toque onde entra a parada depois de "${_pendingStop!.name}"',
    _ => null,
  };

  /// O toque no mapa muda de significado conforme o modo ativo.
  Future<void> _onMapPoint(LatLng point) async {
    final action = _pendingAction;
    final target = _pendingStop;
    if (action == null) {
      await _promptAddStop(point);
      return;
    }
    setState(() {
      _pendingAction = null;
      _pendingStop = null;
    });

    if (action == _StopAction.move) {
      await _run(
        () => _service.updateStop(
          widget.route.id,
          target!.id,
          latitude: point.latitude,
          longitude: point.longitude,
        ),
        'Parada movida',
      );
      return;
    }

    final name = await _promptText(
      title: 'Parada depois de "${target!.name}"',
      hint: 'Ex.: Posto de saúde',
      helper:
          '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
    );
    if (name == null) return;
    await _run(
      () => _service.addStop(
        widget.route.id,
        name,
        latitude: point.latitude,
        longitude: point.longitude,
        sequence: target.sequence + 1,
      ),
      'Parada inserida',
    );
  }

  Future<void> _onTapStop(MapStop tapped) async {
    final stop = _stops.firstWhere((s) => s.id == tapped.id);
    final action = await showModalBottomSheet<_StopAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                stop.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('Parada ${stop.sequence}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_with, color: AppColors.deepTeal),
              title: const Text('Mover para outro local'),
              onTap: () => Navigator.pop(context, _StopAction.move),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_location_alt_outlined,
                color: AppColors.deepTeal,
              ),
              title: const Text('Inserir parada depois desta'),
              onTap: () => Navigator.pop(context, _StopAction.insertAfter),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.deepTeal,
              ),
              title: const Text('Renomear'),
              onTap: () => Navigator.pop(context, _StopAction.rename),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text('Remover'),
              onTap: () => Navigator.pop(context, _StopAction.remove),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _StopAction.move:
      case _StopAction.insertAfter:
        setState(() {
          _pendingAction = action;
          _pendingStop = stop;
        });
      case _StopAction.rename:
        final name = await _promptText(
          title: 'Renomear parada',
          hint: stop.name,
        );
        if (name == null) return;
        await _run(
          () => _service.updateStop(widget.route.id, stop.id, name: name),
          'Parada renomeada',
        );
      case _StopAction.remove:
        await _run(
          () => _service.deleteStop(widget.route.id, stop.id),
          'Parada removida',
        );
    }
  }

  Future<void> _promptAddStop(LatLng point) async {
    final name = await _promptText(
      title: 'Nova parada',
      hint: 'Ex.: Rodoviária',
      helper:
          '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
    );
    if (name == null) return;
    await _run(
      () => _service.addStop(
        widget.route.id,
        name,
        latitude: point.latitude,
        longitude: point.longitude,
      ),
      'Parada adicionada',
    );
  }

  Future<void> _promptAddVehicle() async {
    final labelCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo veículo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Identificação'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidade'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    final capacity = int.tryParse(capacityCtrl.text.trim());
    if (ok != true || labelCtrl.text.trim().isEmpty || capacity == null) return;
    await _run(
      () =>
          _service.addVehicle(widget.route.id, labelCtrl.text.trim(), capacity),
      'Veículo adicionado',
    );
  }

  Future<void> _promptLinkInstitution(List<InstitutionModel> options) async {
    final chosen = await showDialog<InstitutionModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Vincular instituição'),
        children: [
          for (final institution in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, institution),
              child: Text(institution.name),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await _run(
      () => _institutionService.linkRoute(chosen.id, widget.route.id),
      'Instituição vinculada',
    );
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    String? helper,
  }) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint, helperText: helper),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    return (ok == true && text.isNotEmpty) ? text : null;
  }
}

enum _StopAction { move, insertAfter, rename, remove }
