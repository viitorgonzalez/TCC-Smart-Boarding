import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/daily_list_model.dart';
import '../services/list_service.dart';

class AdminListProvider extends ChangeNotifier {
  final ListService _service;

  AsyncValue<List<DailyList>> _state = const AsyncLoading();
  AsyncValue<List<DailyList>> get state => _state;

  AdminListProvider(this._service);

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getTodayLists());
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }
}
