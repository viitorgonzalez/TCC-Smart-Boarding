import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/list_with_enrollment.dart';
import '../services/list_service.dart';

/// Gerencia as listas do dia + status de inscrição do estudante logado.
/// A inscrição (enrolled + direção) vem direto de GET /lists/today.
class StudentListProvider extends ChangeNotifier {
  final ListService _service;
  String _userEmail = '';

  AsyncValue<List<ListWithEnrollment>> _state = const AsyncLoading();
  AsyncValue<List<ListWithEnrollment>> get state => _state;

  StudentListProvider(this._service);

  /// Chamado via ProxyProvider quando o email do usuário muda.
  void setUserEmail(String email) {
    if (_userEmail == email) return;
    _userEmail = email;
    if (email.isNotEmpty) load();
  }

  Future<void> load() async {
    // Sem e-mail nao da pra dizer quem esta inscrito. Sair calado deixava a tela
    // girando pra sempre -- era assim que a sessao do Google (que nao mandava
    // e-mail) aparecia pro aluno: carregamento infinito, sem erro nenhum.
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

  /// Entra na lista com a direção escolhida (ou troca a direção se já inscrito).
  Future<void> enter(String listId, String tripType) async {
    await _service.addEntry(listId, tripType: tripType);
    await load();
  }

  Future<void> leave(String listId) async {
    await _service.removeEntry(listId);
    await load();
  }
}
