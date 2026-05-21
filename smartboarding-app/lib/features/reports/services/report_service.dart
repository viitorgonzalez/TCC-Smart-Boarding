import 'package:dio/dio.dart';
import 'package:smartboarding_app/core/constants/api_constants.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';
import 'package:smartboarding_app/features/reports/models/report_model.dart';

class ReportService {
  final Dio _dio = DioClient.instance;

  /// Returns (reports, totalPages)
  Future<(List<ReportSummaryModel>, int)> getAll({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.reports,
        queryParameters: {'page': page, 'size': size},
      );
      final pageData = res.data['data'] as Map<String, dynamic>;
      final content = pageData['content'] as List<dynamic>;
      final totalPages = (pageData['totalPages'] as num).toInt();
      final reports = content
          .map((e) => ReportSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (reports, totalPages);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<ReportDetailModel> getById(String id) async {
    try {
      final res = await _dio.get('${ApiConstants.reports}/$id');
      return ReportDetailModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada. Faça login novamente.';
    if (e.response?.statusCode == 404) return 'Relatório não encontrado.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tempo de conexão esgotado. Verifique a rede.';
    }
    return 'Erro ao conectar com o servidor.';
  }
}
