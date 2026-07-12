import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../../lists/models/daily_list_model.dart';
import '../../lists/services/list_service.dart';
import '../services/driver_service.dart';

class DriverProvider extends ChangeNotifier {
  final ListService _listService;
  final DriverService _driverService;

  DriverProvider(this._listService, this._driverService);

  AsyncValue<List<DailyList>> _state = const AsyncLoading();
  AsyncValue<List<DailyList>> get state => _state;

  DailyList? _selected;
  DailyList? get selected => _selected;

  bool _sending = false;
  bool get sending => _sending;

  Future<void> load() async {
    _state = const AsyncLoading();
    _selected = null;
    notifyListeners();
    try {
      final lists = await _listService.getTodayLists();
      _state = AsyncData(lists);
      _selected = lists.isNotEmpty ? lists.first : null;
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  void select(DailyList list) {
    _selected = list;
    notifyListeners();
  }

  /// Envia a notificação de saída para a lista selecionada.
  /// Retorna quantos foram notificados. Lança em caso de erro.
  Future<int> sendDeparture(String message) async {
    final list = _selected;
    if (list == null) {
      throw StateError('Nenhuma lista selecionada');
    }
    _sending = true;
    notifyListeners();
    try {
      return await _driverService.sendDeparture(list.id, body: message);
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
