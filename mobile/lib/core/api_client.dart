import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_storage.dart';

class UnauthorizedException implements Exception {}

String getApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Сервер не отвечает';
    }
  }
  return 'Неизвестная ошибка';
}

class ApiClient {
  ApiClient(this._storage, {void Function()? onUnauthorized})
      : _onUnauthorized = onUnauthorized {
    dio = Dio(
      BaseOptions(
        baseUrl: '$defaultApiBaseUrl/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401) {
            await _storage.clearToken();
            _onUnauthorized?.call();
          }
          handler.next(err);
        },
      ),
    );
  }

  final AuthStorage _storage;
  final void Function()? _onUnauthorized;
  late final Dio dio;
}
