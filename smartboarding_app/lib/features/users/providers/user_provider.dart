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

  /// A lista cresce sem teto, então vem por partes: a tela pede a próxima ao
  /// chegar perto do fim, sem numeração de página — pra quem usa continua
  /// sendo uma lista só.
  bool _hasMore = true;
  bool _carregandoMais = false;
  int _pagina = 0;

  bool get hasMore => _hasMore;

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      final result = await _service.getUsers(routeId: routeId);
      _state = AsyncData(result.items);
      _hasMore = result.hasMore;
      _pagina = 1;
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    // A guarda evita disparar de novo a cada quadro de rolagem — sem ela o
    // scroll pediria a mesma página dezenas de vezes.
    if (!_hasMore || _carregandoMais) return;
    if (_state case AsyncData(:final value)) {
      _carregandoMais = true;
      try {
        final result = await _service.getUsers(routeId: routeId, page: _pagina);
        _state = AsyncData([...value, ...result.items]);
        _hasMore = result.hasMore;
        _pagina++;
        notifyListeners();
      } catch (_) {
        // Falhar ao buscar mais não pode apagar o que já está na tela.
      } finally {
        _carregandoMais = false;
      }
    }
  }
}
