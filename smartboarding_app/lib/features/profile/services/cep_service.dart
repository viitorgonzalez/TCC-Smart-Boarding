import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/address_model.dart';

class CepService {
  static const _base = 'https://viacep.com.br/ws';
  static const _digitos = 8;

  final Dio _dio;

  CepService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              responseType: ResponseType.json,
            ),
          );

  @visibleForTesting
  Dio get dio => _dio;

  Future<Address?> lookup(String cep) async {
    final limpo = cep.replaceAll(RegExp(r'\D'), '');
    if (limpo.length != _digitos) return null;

    try {
      final resposta = await _dio.get<Map<String, dynamic>>(
        '$_base/$limpo/json/',
      );
      final dados = resposta.data;
      if (dados == null || _temErro(dados)) return null;

      return Address(
        zipCode: '${limpo.substring(0, 5)}-${limpo.substring(5)}',
        street: _texto(dados['logradouro']),
        neighborhood: _texto(dados['bairro']),
        city: _texto(dados['localidade']),
        state: _texto(dados['uf']),
      );
    } catch (_) {
      return null;
    }
  }

  static bool _temErro(Map<String, dynamic> dados) {
    final erro = dados['erro'];
    return erro == true || erro == 'true';
  }

  static String? _texto(Object? valor) {
    final t = valor?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
