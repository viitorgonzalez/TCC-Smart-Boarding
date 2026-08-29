import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/admin_stats_model.dart';
import '../services/admin_stats_service.dart';

class AdminStatsProvider extends ChangeNotifier {
  final AdminStatsService _service;

  AsyncValue<AdminStats> _state = const AsyncLoading();
  AsyncValue<AdminStats> get state => _state;

  AdminStatsProvider(this._service);

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getStats());
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }
}
