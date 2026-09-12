import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/institution_model.dart';
import '../services/institution_service.dart';

/// Catálogo de instituições. Existe separado da rota porque instituição não
/// pertence a rota nenhuma: ela é cadastrada uma vez e depois atendida por uma
/// rota — ou por nenhuma, enquanto não houver transporte pra lá.
class InstitutionProvider extends ChangeNotifier {
  final InstitutionService _service;

  InstitutionProvider([InstitutionService? service])
    : _service = service ?? InstitutionService();

  AsyncValue<List<InstitutionModel>> _state = const AsyncLoading();
  AsyncValue<List<InstitutionModel>> get state => _state;

  List<InstitutionModel> get all => switch (_state) {
    AsyncData(:final value) => value,
    _ => const [],
  };

  /// As que ainda não têm rota. É a lista que a tela da rota oferece pra
  /// vincular — mostrar as já vinculadas convidaria a roubar de outra rota.
  List<InstitutionModel> get unlinked =>
      all.where((i) => i.routeId == null).toList();

  List<InstitutionModel> servedBy(String routeId) =>
      all.where((i) => i.routeId == routeId).toList();

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getInstitutions());
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> create(String name, {String? address, String? routeId}) async {
    await _service.createInstitution(name, address: address, routeId: routeId);
    await load();
  }

  Future<void> update(String id, {String? name, String? address}) async {
    await _service.updateInstitution(id, name: name, address: address);
    await load();
  }

  /// [routeId] nulo desvincula.
  Future<void> linkRoute(String id, String? routeId) async {
    await _service.linkRoute(id, routeId);
    await load();
  }

  Future<void> remove(String id) async {
    await _service.deleteInstitution(id);
    await load();
  }
}
