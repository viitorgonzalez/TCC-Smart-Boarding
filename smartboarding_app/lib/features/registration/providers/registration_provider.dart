import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/institution_model.dart';
import '../models/invite_info_model.dart';
import '../models/registration_request_model.dart';
import '../services/institution_service.dart';
import '../services/registration_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _registrationService;
  final InstitutionService _institutionService;

  AsyncValue<List<InstitutionModel>> _institutions = const AsyncLoading();
  AsyncValue<List<RegistrationRequestModel>> _pending = const AsyncLoading();
  AsyncValue<void> _submitState = const AsyncData(null);
  AsyncValue<InviteInfoModel> _invite = const AsyncLoading();
  AsyncValue<void> _resendState = const AsyncData(null);

  AsyncValue<List<InstitutionModel>> get institutions => _institutions;
  AsyncValue<List<RegistrationRequestModel>> get pending => _pending;
  AsyncValue<void> get submitState => _submitState;
  AsyncValue<InviteInfoModel> get invite => _invite;
  AsyncValue<void> get resendState => _resendState;

  RegistrationProvider(this._registrationService, this._institutionService);

  Future<void> validateInvite(String token) async {
    _invite = const AsyncLoading();
    notifyListeners();
    try {
      final result = await _registrationService.getInvite(token);
      _invite = AsyncData(result);
    } catch (e) {
      _invite = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> resendCode(String email) async {
    _resendState = const AsyncLoading();
    notifyListeners();
    try {
      await _registrationService.resendCode(email);
      _resendState = const AsyncData(null);
    } catch (e) {
      _resendState = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> loadInstitutions() async {
    _institutions = const AsyncLoading();
    notifyListeners();
    try {
      final result = await _institutionService.getInstitutions();
      _institutions = AsyncData(result);
    } catch (e) {
      _institutions = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> loadPending() async {
    _pending = const AsyncLoading();
    notifyListeners();
    try {
      final result = await _registrationService.getPending();
      _pending = AsyncData(result);
    } catch (e) {
      _pending = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> approve(String id) async {
    await _registrationService.approve(id);
    await loadPending();
  }

  Future<void> reject(String id, String reason) async {
    await _registrationService.reject(id, reason);
    await loadPending();
  }

  Future<void> submit({
    required String token,
    required String fullName,
    required String password,
    required String institutionId,
    String? course,
    String? phone,
    String? address,
    String? birthDate,
  }) async {
    _submitState = const AsyncLoading();
    notifyListeners();
    try {
      await _registrationService.submit(
        token: token,
        fullName: fullName,
        password: password,
        institutionId: institutionId,
        course: course,
        phone: phone,
        address: address,
        birthDate: birthDate,
      );
      _submitState = const AsyncData(null);
    } catch (e) {
      _submitState = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }
}
