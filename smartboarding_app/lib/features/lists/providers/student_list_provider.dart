import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/list_with_enrollment.dart';
import '../services/list_service.dart';

class StudentListProvider extends ChangeNotifier {
  final ListService _service;
  String _userEmail = '';

  AsyncValue<List<ListWithEnrollment>> _state = const AsyncLoading();
  AsyncValue<List<ListWithEnrollment>> get state => _state;

  StudentListProvider(this._service);

  void setUserEmail(String email) {
    if (_userEmail == email) return;
    _userEmail = email;
    if (email.isNotEmpty) load();
  }

  Future<void> load() async {
    if (_userEmail.isEmpty) {
      _state = const AsyncError('Sessão sem e-mail. Entre novamente.');
      notifyListeners();
      return;
    }
    _state = const AsyncLoading();
    notifyListeners();
    try {
      final lists = await _service.getTodayLists();
      _state = AsyncData(
        lists
            .map(
              (l) => ListWithEnrollment(
                list: l,
                isEnrolled: l.enrolled,
                tripType: l.tripType,
              ),
            )
            .toList(),
      );
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> enter(String listId, String tripType) async {
    await _service.addEntry(listId, tripType: tripType);
    await load();
  }

  Future<void> leave(String listId) async {
    await _service.removeEntry(listId);
    await load();
  }
}
