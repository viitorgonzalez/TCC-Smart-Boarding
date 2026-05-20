import 'package:dio/dio.dart';
import 'package:smartboarding_app/core/constants/api_constants.dart';
import 'package:smartboarding_app/core/services/storage_service.dart';

class DioClient {
  static Dio? _instance;
  static final StorageService _storage = StorageService();

  static Dio get instance {
    _instance ??= _build();
    return _instance!;
  }

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final auth = await _storage.getAuthToken();
        if (auth != null) {
          options.headers['Authorization'] = 'Bearer ${auth.token}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.clearAuthToken();
        }
        handler.next(error);
      },
    ));

    return dio;
  }
}
