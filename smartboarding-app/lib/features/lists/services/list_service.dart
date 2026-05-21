import 'package:dio/dio.dart';
import 'package:smartboarding_app/core/constants/api_constants.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/models/list_entry_model.dart';

class ListService {
  final Dio _dio = DioClient.instance;

  Future<List<DailyListModel>> getTodayLists() async {
    try {
      final res = await _dio.get(ApiConstants.listsToday);
      final data = res.data['data'] as List<dynamic>;
      return data
          .map((e) => DailyListModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<List<ListEntryModel>> getEntries(String listId) async {
    try {
      final res = await _dio.get('${ApiConstants.lists}/$listId/entries');
      final data = res.data['data'] as List<dynamic>;
      return data
          .map((e) => ListEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> addEntry(String listId) async {
    try {
      await _dio.post('${ApiConstants.lists}/$listId/entries');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Você já está inscrito nesta lista.');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('Lista encerrada ou inscrição inválida.');
      }
      throw Exception(_handleError(e));
    }
  }

  Future<void> removeEntry(String listId) async {
    try {
      await _dio.delete('${ApiConstants.lists}/$listId/entries');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Você não está inscrito nesta lista.');
      }
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) return 'Sessão expirada. Faça login novamente.';
    if (e.response?.statusCode == 403) return 'Sem permissão para esta operação.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tempo de conexão esgotado. Verifique a rede.';
    }
    return 'Erro ao conectar com o servidor.';
  }
}
