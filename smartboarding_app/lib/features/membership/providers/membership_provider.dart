import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../../routes/models/route_model.dart';
import '../services/membership_service.dart';

/// Rotas do aluno. Separado do resto porque a home inteira depende dele: sem
/// rota nenhuma não há lista, aviso nem trajeto pra mostrar.
class MembershipProvider extends ChangeNotifier {
  final MembershipService _service;

  MembershipProvider([MembershipService? service])
    : _service = service ?? MembershipService();

  AsyncValue<List<RouteModel>> _state = const AsyncLoading();
  AsyncValue<List<RouteModel>> get state => _state;

  /// Rota em foco. Com várias, a home mostra uma por vez.
  String? _selectedId;
  String? get selectedId => _selectedId;

  List<RouteModel> get routes => switch (_state) {
    AsyncData(:final value) => value,
    _ => const [],
  };

  bool get hasNoRoute => switch (_state) {
    AsyncData(:final value) => value.isEmpty,
    _ => false,
  };

  RouteModel? get selected {
    final all = routes;
    if (all.isEmpty) return null;
    return all.firstWhere((r) => r.id == _selectedId, orElse: () => all.first);
  }

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      final all = await _service.myRoutes();
      _state = AsyncData(all);
      // Rota selecionada que sumiu (o aluno saiu dela) nao pode continuar em
      // foco, senao a home fica pedindo dado de uma rota que ele nao tem mais.
      if (_selectedId != null && !all.any((r) => r.id == _selectedId)) {
        _selectedId = null;
      }
      _selectedId ??= all.isEmpty ? null : all.first.id;
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  void select(String routeId) {
    if (_selectedId == routeId) return;
    _selectedId = routeId;
    notifyListeners();
  }

  /// Entra na rota do código. Deixa a exceção subir: a tela precisa da mensagem
  /// pra distinguir código errado de expirado.
  Future<RouteModel> join(String code) async {
    final route = await _service.joinWithCode(code);
    await load();
    _selectedId = route.id;
    notifyListeners();
    return route;
  }

  Future<void> leave(String routeId) async {
    await _service.leave(routeId);
    await load();
  }
}
