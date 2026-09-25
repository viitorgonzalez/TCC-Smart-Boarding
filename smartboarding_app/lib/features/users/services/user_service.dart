import '../../../core/pagination/page_result.dart';
import '../../../core/services/dio_client.dart';
import '../models/student_profile_model.dart';
import '../models/user_model.dart';

class UserService {
  final _dio = DioClient.instance;

  /// [routeId] nulo traz o sistema inteiro; o app usa o filtro por rota porque
  /// a base cresce sem teto e o admin trabalha por rota.
  ///
  /// Vem por partes: a tela pede a próxima conforme o admin rola, em vez de
  /// baixar a base inteira pra mostrar os primeiros dez nomes.
  Future<PageResult<UserModel>> getUsers({
    String? routeId,
    int page = 0,
  }) async {
    final response = await _dio.get(
      '/api/users',
      queryParameters: {'routeId': ?routeId, 'page': page},
    );
    return PageResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
      UserModel.fromJson,
    );
  }

  /// Todas as páginas de uma vez.
  ///
  /// Pra telas com busca por nome: procurar dentro de um pedaço encontraria só
  /// quem calhou de vir na primeira página, e o resultado pareceria um bug.
  Future<List<UserModel>> getAllUsers({String? routeId}) async {
    final todos = <UserModel>[];
    var pagina = 0;
    while (true) {
      final result = await getUsers(routeId: routeId, page: pagina);
      todos.addAll(result.items);
      if (!result.hasMore) return todos;
      pagina++;
    }
  }

  /// Só o número de administradores. A ficha do usuário precisa dele pra saber
  /// se está olhando a última conta admin; contar no cliente exigiria baixar
  /// `/api/users` inteiro — e-mail, telefone, endereço e nascimento de toda a
  /// base — a cada vez que a folha abre.
  Future<int> getAdminCount() async {
    final response = await _dio.get('/api/users/admins/count');
    return (response.data['data']['count'] as num).toInt();
  }

  Future<StudentProfile> getProfile(String userId) async {
    final response = await _dio.get('/api/users/$userId/profile');
    return StudentProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<StudentProfile> setActive(String userId, bool active) async {
    final response = await _dio.patch(
      '/api/users/$userId/status',
      data: {'active': active},
    );
    return StudentProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Concede ou retira acesso administrativo. Não cria conta — a conta já é da
  /// pessoa.
  Future<StudentProfile> setRole(String userId, String role) async {
    final response = await _dio.patch(
      '/api/users/$userId/role',
      data: {'role': role},
    );
    return StudentProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
