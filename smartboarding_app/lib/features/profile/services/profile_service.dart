import '../../../core/services/dio_client.dart';
import '../models/address_model.dart';
import '../models/profile_update_model.dart';

class ProfileService {
  final _dio = DioClient.instance;

  /// Manda só o que mudou: campo ausente significa "não pedi mudança nele".
  ///
  /// Sobrou pouco: endereço, telefone e curso têm caminhos diretos
  /// ([updateAddress] e [updateOwnProfile]). O que passa por aqui é o que
  /// decide em qual transporte a pessoa entra.
  Future<ProfileUpdate> requestUpdate({
    String? fullName,
    String? institutionId,
    String? birthDate,
  }) async {
    final response = await _dio.post(
      '/api/me/profile-requests',
      data: {
        'fullName': ?fullName,
        'institutionId': ?institutionId,
        'birthDate': ?birthDate,
      },
    );
    return ProfileUpdate.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Nulo quando não há pedido em análise.
  Future<ProfileUpdate?> myPending() async {
    final response = await _dio.get('/api/me/profile-requests/pending');
    final data = response.data['data'];
    return data == null
        ? null
        : ProfileUpdate.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProfileUpdate>> pending() async {
    final response = await _dio.get('/api/profile-requests');
    final List data = response.data['data'] as List;
    return data
        .map((e) => ProfileUpdate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approve(String id) async {
    await _dio.post('/api/profile-requests/$id/approve');
  }

  Future<void> reject(String id, String reason) async {
    await _dio.post(
      '/api/profile-requests/$id/reject',
      data: {'reason': reason},
    );
  }

  /// Último pedido em qualquer estado: é por ele que a recusa e o motivo
  /// chegam ao aluno. O /pending só devolve PENDING.
  Future<ProfileUpdate?> myLatest() async {
    final response = await _dio.get('/api/me/profile-requests/latest');
    final data = response.data['data'];
    return data == null
        ? null
        : ProfileUpdate.fromJson(data as Map<String, dynamic>);
  }

  /// Salva o endereço direto, sem passar pela fila do admin: ele diz onde o
  /// aluno embarca, não em qual transporte ele entra. Como é pré-requisito pra
  /// entrar na lista, depender de aprovação deixaria a pessoa travada esperando.
  Future<Address> updateAddress(Address endereco) async {
    final response = await _dio.put('/api/me/address', data: endereco.toJson());
    return Address.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Telefone e curso, salvos direto. Mesma razão do endereço: alcançam a
  /// pessoa ou a descrevem, mas não decidem em qual transporte ela entra.
  Future<void> updateOwnProfile({String? phone, String? course}) async {
    await _dio.put(
      '/api/me/profile',
      data: {'phone': ?phone, 'course': ?course},
    );
  }

  Future<Me> me() async {
    final response = await _dio.get('/api/me');
    return Me.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Define a senha local de quem entrou pelo Google e ainda não tem uma.
  Future<void> setLocalPassword(String password) async {
    await _dio.post('/api/me/password', data: {'password': password});
  }

  /// Troca a senha de quem já tem uma. Verbo diferente do POST: lá se cria a
  /// primeira senha, aqui se substitui uma existente provando posse da antiga.
  Future<void> changePassword(String current, String novaSenha) async {
    await _dio.put(
      '/api/me/password',
      data: {'currentPassword': current, 'newPassword': novaSenha},
    );
  }

  /// Instituições do próprio aluno. É pré-requisito pra entrar em rota, por
  /// isso vive sob /me e não na área do admin.
  Future<List<String>> myInstitutions() async {
    final response = await _dio.get('/api/me/institutions');
    return (response.data['data'] as List).map((e) => e as String).toList();
  }

  Future<void> addInstitution(String institutionId) async {
    await _dio.post('/api/me/institutions/$institutionId');
  }

  Future<void> removeInstitution(String institutionId) async {
    await _dio.delete('/api/me/institutions/$institutionId');
  }
}
