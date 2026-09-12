import '../../../core/services/dio_client.dart';
import '../../routes/models/route_model.dart';

/// As rotas do próprio usuário. O id sai do token no backend — o app nunca
/// manda userId, senão daria pra operar em nome de outro.
class MembershipService {
  final _dio = DioClient.instance;

  Future<List<RouteModel>> myRoutes() async {
    final response = await _dio.get('/api/me/routes');
    final List data = response.data['data'] as List;
    return data
        .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RouteModel> joinWithCode(String code) async {
    final response = await _dio.post('/api/me/routes', data: {'code': code});
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> leave(String routeId) async {
    await _dio.delete('/api/me/routes/$routeId');
  }
}
