import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service;

  AsyncValue<List<UserModel>> _state = const AsyncLoading();
  AsyncValue<List<UserModel>> get state => _state;

  UserProvider(this._service);

  String? routeId;

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getUsers(routeId: routeId));
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }
}
