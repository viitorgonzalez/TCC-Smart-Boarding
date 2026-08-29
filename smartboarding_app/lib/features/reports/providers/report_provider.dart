import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;

  AsyncValue<List<ReportSummary>> _state = const AsyncLoading();
  bool _hasMore = true;
  bool _isFetchingMore = false;
  int _page = 0;

  AsyncValue<List<ReportSummary>> get state => _state;
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  ReportProvider(this._service);

  Future<void> load() async {
    _state = const AsyncLoading();
    _page = 0;
    _hasMore = true;
    notifyListeners();
    try {
      final result = await _service.getReports(0);
      _state = AsyncData(result.items);
      _hasMore = result.hasMore;
      _page = 1;
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  /// Carrega a próxima página (scroll infinito).
  Future<void> loadMore() async {
    if (!_hasMore || _isFetchingMore) return;
    if (_state case AsyncData(:final value)) {
      _isFetchingMore = true;
      notifyListeners();
      try {
        final result = await _service.getReports(_page);
        _state = AsyncData([...value, ...result.items]);
        _hasMore = result.hasMore;
        _page++;
      } catch (_) {
        // mantém dados existentes em caso de erro de paginação
      }
      _isFetchingMore = false;
      notifyListeners();
    }
  }
}
