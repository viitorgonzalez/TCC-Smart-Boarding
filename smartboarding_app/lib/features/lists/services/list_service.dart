import '../../../core/services/dio_client.dart';
import '../../reports/models/attendance_model.dart';
import '../models/daily_list_model.dart';
import '../models/list_entry_model.dart';

class ListService {
  final _dio = DioClient.instance;

  Future<List<DailyList>> getTodayLists() async {
    final response = await _dio.get('/api/lists/today');
    final List data = response.data['data'] as List;
    return data
        .map((e) => DailyList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ListEntry>> getEntries(String listId) async {
    final response = await _dio.get('/api/lists/$listId/entries');
    final List data = response.data['data'] as List;
    return data
        .map((e) => ListEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addEntry(String listId, {String? tripType}) async {
    final data = <String, dynamic>{};
    if (tripType != null) data['tripType'] = tripType;
    await _dio.post('/api/lists/$listId/entries', data: data);
  }

  Future<void> removeEntry(String listId) async {
    await _dio.delete('/api/lists/$listId/entries');
  }

  /// Dias de presença do aluno logado nos últimos [months] meses.
  Future<List<AttendanceDay>> getMyAttendance({int months = 6}) async {
    final response = await _dio.get(
      '/api/lists/my-attendance',
      queryParameters: {'months': months},
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => AttendanceDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DailyList>> getListsByDate(DateTime date) async {
    final iso =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      '/api/lists',
      queryParameters: {'date': iso},
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => DailyList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createList(String routeId, DateTime date) async {
    final iso =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _dio.post('/api/lists', data: {'routeId': routeId, 'date': iso});
  }

  /// [reason] é obrigatório: vira o aviso enviado aos alunos da rota.
  Future<void> setListStatus(
    String listId,
    String status,
    String reason,
  ) async {
    await _dio.patch(
      '/api/lists/$listId',
      data: {'status': status, 'reason': reason},
    );
  }

  /// O backend recusa se a lista já tiver relatório gerado (RN8).
  Future<void> deleteList(String listId) async {
    await _dio.delete('/api/lists/$listId');
  }

  /// Inclusão pelo admin: entra mesmo com a lista fechada. [issueWarning] é a
  /// escolha dele — nem toda inclusão tardia é falta do aluno.
  Future<void> addEntryAsAdmin(
    String listId, {
    required String userId,
    required bool issueWarning,
    String? tripType,
    String? warningReason,
  }) async {
    await _dio.post(
      '/api/lists/$listId/entries/admin',
      data: {
        'userId': userId,
        'issueWarning': issueWarning,
        'tripType': ?tripType,
        'warningReason': ?warningReason,
      },
    );
  }

  Future<void> removeEntryAsAdmin(String listId, String userId) async {
    await _dio.delete('/api/lists/$listId/entries/$userId');
  }
}
