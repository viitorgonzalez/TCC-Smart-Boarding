import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';
import 'package:smartboarding_app/features/profile/services/cep_service.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late CepService service;

  setUp(() {
    dio = _MockDio();
    service = CepService(dio: dio);
  });

  void responde(Map<String, dynamic> corpo, {int status = 200}) {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response(
        data: corpo,
        statusCode: status,
        requestOptions: RequestOptions(path: ''),
      ),
    );
  }

  const respostaBoa = {
    'cep': '35570-000',
    'logradouro': 'Avenida Doutor Arnaldo de Senna',
    'bairro': 'Água Vermelha',
    'localidade': 'Formiga',
    'uf': 'MG',
  };

  test('preenche rua, bairro, cidade e UF a partir do CEP', () async {
    responde(respostaBoa);

    final endereco = await service.lookup('35570000');

    expect(endereco!.street, 'Avenida Doutor Arnaldo de Senna');
    expect(endereco.neighborhood, 'Água Vermelha');
    expect(endereco.city, 'Formiga');
    expect(endereco.state, 'MG');
    expect(endereco.zipCode, '35570-000');
  });

  test('aceita CEP digitado com máscara', () async {
    responde(respostaBoa);

    expect(await service.lookup('35570-000'), isNotNull);
  });

  /// A armadilha do ViaCEP: CEP inexistente responde **200** com {"erro": true}.
  /// Tratar só o status deixaria passar resposta vazia como se fosse endereço
  /// bom, e o aluno salvaria um endereço em branco achando que preencheu.
  test('CEP inexistente devolve nulo mesmo vindo com HTTP 200', () async {
    responde({'erro': true});

    expect(await service.lookup('99999999'), isNull);
  });

  /// O mesmo campo já veio como string em versões diferentes do serviço.
  test('trata erro vindo como string tambem', () async {
    responde({'erro': 'true'});

    expect(await service.lookup('99999999'), isNull);
  });

  test('servico fora do ar devolve nulo em vez de estourar', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(await service.lookup('35570000'), isNull);
  });

  test('resposta sem corpo devolve nulo', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async =>
          Response(data: null, requestOptions: RequestOptions(path: '')),
    );

    expect(await service.lookup('35570000'), isNull);
  });

  /// Entrada que nem CEP é não merece uma ida à rede: o formulário consulta a
  /// cada tecla, e um request por dígito digitado é desperdício puro.
  test('CEP incompleto nem chega a consultar', () async {
    expect(await service.lookup('3557'), isNull);

    verifyNever(() => dio.get<Map<String, dynamic>>(any()));
  });

  test('CEP com letra nem chega a consultar', () async {
    expect(await service.lookup('3557000a'), isNull);

    verifyNever(() => dio.get<Map<String, dynamic>>(any()));
  });

  /// O ViaCEP é de terceiro. Reaproveitar o cliente da API mandaria o Bearer
  /// da sessão junto do request — entregando o token de um aluno a um host
  /// que não tem nada a ver com o sistema.
  test('nao reaproveita o cliente autenticado da API', () {
    final proprio = CepService().dio;

    expect(proprio, isNot(same(DioClient.instance)));
    expect(proprio.options.headers.containsKey('Authorization'), isFalse);
    expect(proprio.options.baseUrl, isNot(DioClient.instance.options.baseUrl));
  });
}
