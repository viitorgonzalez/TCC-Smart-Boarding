import '../../../core/pagination/page_result.dart';
import '../../../core/services/dio_client.dart';
import '../models/student_profile_model.dart';
import '../models/user_model.dart';

class UserService {
  final _dio = DioClient.instance;

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
