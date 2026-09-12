import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/trip_status_model.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _service;
  final String listId;

  AsyncValue<TripStatus> _state = const AsyncLoading();
  AsyncValue<TripStatus> get state => _state;

  /// Acao em voo. Sem isso o duplo toque vira dois checkpoints, e o segundo
  /// morre em erro na cara de quem esta dirigindo.
  bool _busy = false;
  bool get busy => _busy;

  TripProvider(this._service, this.listId);

  Future<void> load() => _run(() => _service.status(listId));

  Future<void> start() => _run(() => _service.start(listId));

  Future<void> checkpoint(String stopId) =>
      _run(() => _service.checkpoint(listId, stopId));

  Future<void> finish() => _run(() => _service.finish(listId));

  Future<void> _run(Future<TripStatus> Function() action) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      _state = AsyncData(await action());
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
