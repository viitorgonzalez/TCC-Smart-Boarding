import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';

class RouteProvider extends ChangeNotifier {
  final RouteService _service;

  AsyncValue<List<RouteModel>> _state = const AsyncLoading();
  AsyncValue<List<RouteModel>> get state => _state;

  RouteProvider(this._service);

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getRoutes());
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  /// Cria rota e recarrega a lista. Lança exceção em caso de erro.
  Future<void> create(String name, String? description) async {
    await _service.createRoute(name, description);
    await load();
  }

  Future<void> update(String id, String name, String? description) async {
    await _service.updateRoute(id, name, description);
    await load();
  }

  Future<void> delete(String id) async {
    await _service.deleteRoute(id);
    await load();
  }
}
