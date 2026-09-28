import 'package:flutter/foundation.dart';

import '../models/profile_update_model.dart';
import '../services/profile_service.dart';

/// Quem é o usuário da sessão, compartilhado entre telas.
///
/// Existe porque duas telas distantes precisam da mesma resposta: o perfil
/// mostra o que falta preencher, e o card da lista precisa saber disso pra
/// avisar ANTES de o aluno tocar no botão e tomar erro.
class MeProvider extends ChangeNotifier {
  final ProfileService _service;

  MeProvider([ProfileService? service])
    : _service = service ?? ProfileService();

  Me? _me;
  Me? get me => _me;

  /// Enquanto não carregou, nada de aviso: mostrar "falta preencher" antes de
  /// saber o que falta acusaria de errado quem está com tudo em ordem.
  List<String> get faltando => _me?.faltandoEmPortugues ?? const [];

  /// Falha fica em silêncio de propósito: o /me alimenta avisos, não a
  /// operação. Quebrar a tela inteira porque um aviso não carregou seria
  /// trocar um incômodo por um bloqueio.
  Future<void> load() async {
    try {
      _me = await _service.me();
    } catch (_) {
      return;
    }
    notifyListeners();
  }
}
