import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  bool _isSending = false;
  bool get isSending => _isSending;

  NotificationProvider(this._service);

  Future<void> broadcast(
    String title,
    String body, {
    required String routeId,
    int? durationHours,
  }) async {
    _isSending = true;
    notifyListeners();
    try {
      await _service.broadcast(
        title,
        body,
        routeId: routeId,
        durationHours: durationHours,
      );
    } catch (e) {
      throw AppException(AppException.fromError(e));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
