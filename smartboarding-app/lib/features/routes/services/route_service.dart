import 'package:dio/dio.dart';
import 'package:smartboarding_app/core/constants/api_constants.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';
import 'package:smartboarding_app/features/routes/models/route_model.dart';

class RouteService {
  final Dio _dio = DioClient.instance;

  Future<List<RouteModel>> getAll() async {
    try {
      final res = await _dio.get(ApiConstants.routes);
      final data = res.data['data'] as List<dynamic>;
      return data
          .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<RouteModel> create(String name, String description) async {
    try {
      final res = await _dio.post(
        ApiConstants.routes,
        data: {'name': name, 'description': description},
      );
      return RouteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<RouteModel> update(
      String id, String name, String description) async {
    try {
      final res = await _dio.patch(
        '${ApiConstants.routes}/$id',
        data: {'name': name, 'description': description},
      );
      return RouteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('${ApiConstants.routes}/$id');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada. Faça login novamente.';
    if (e.response?.statusCode == 403) return 'Sem permissão para esta operação.';
    if (e.response?.statusCode == 404) return 'Rota não encontrada.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tempo de conexão esgotado. Verifique a rede.';
    }
    return 'Erro ao conectar com o servidor.';
  }
}
