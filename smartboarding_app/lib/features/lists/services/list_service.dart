import '../../../core/services/dio_client.dart';
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
}
