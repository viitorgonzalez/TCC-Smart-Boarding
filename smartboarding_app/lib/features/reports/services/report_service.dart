import '../../../core/services/dio_client.dart';
import '../models/report_model.dart';

class ReportService {
  final _dio = DioClient.instance;

  /// Retorna a página [page] de relatórios (base 0).
  Future<({List<ReportSummary> items, bool hasMore})> getReports(
    int page,
  ) async {
    final response = await _dio.get(
      '/api/reports',
      queryParameters: {'page': page, 'size': 20},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final content = data['content'] as List;
    final totalPages = data['totalPages'] as int;

    return (
      items: content
          .map((e) => ReportSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: page < totalPages - 1,
    );
  }

  Future<ReportDetail> getById(String id) async {
    final response = await _dio.get('/api/reports/$id');
    return ReportDetail.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
