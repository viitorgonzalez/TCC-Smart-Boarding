import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/address_model.dart';

/// Consulta de CEP no ViaCEP — gratuito, sem chave, o padrão de fato no Brasil.
///
/// Cliente HTTP **próprio**, nunca o [DioClient] da API: aquele injeta o Bearer
/// da sessão em toda requisição, e reaproveitá-lo entregaria o token do aluno a
/// um host de terceiro que não tem nada a ver com o sistema.
///
/// Falha sempre devolve `null` em vez de estourar. O ViaCEP não tem SLA, e um
/// CEP fora do ar não pode impedir alguém de terminar o cadastro e pegar o
/// ônibus — quem chama deixa os campos editáveis à mão.
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

  /// Devolve o endereço com rua, bairro, cidade e UF preenchidos, ou `null`
  /// quando o CEP não existe ou o serviço não responde.
  Future<Address?> lookup(String cep) async {
    final limpo = cep.replaceAll(RegExp(r'\D'), '');
    // O formulário consulta enquanto o aluno digita: sair pra rede a cada
    // tecla seria um request por dígito, todos fadados a 404. Letra some no
    // replaceAll e derruba a contagem, então cai aqui também.
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

  /// CEP inexistente responde **200** com `{"erro": true}` — e o mesmo campo já
  /// veio como string em versões diferentes do serviço. Olhar só o status
  /// deixaria o aluno salvar um endereço em branco achando que preencheu.
  static bool _temErro(Map<String, dynamic> dados) {
    final erro = dados['erro'];
    return erro == true || erro == 'true';
  }

  static String? _texto(Object? valor) {
    final t = valor?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
