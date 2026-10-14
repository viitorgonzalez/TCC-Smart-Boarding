import 'package:flutter/foundation.dart';

import '../models/profile_update_model.dart';
import '../services/profile_service.dart';

class MeProvider extends ChangeNotifier {
  final ProfileService _service;

  MeProvider([ProfileService? service])
    : _service = service ?? ProfileService();

  Me? _me;
  Me? get me => _me;

  List<String> get faltando => _me?.faltandoEmPortugues ?? const [];

  Future<void> load() async {
    try {
      _me = await _service.me();
    } catch (_) {
      return;
    }
    notifyListeners();
  }
}
