import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_storage.dart';

class UnauthorizedException implements Exception {}

class ApiClient {
  ApiClient(this._storage, {void Function()? onUnauthorized}) : _onUnauthorized = onUnauthorized {
    dio = Dio(BaseOptions(baseUrl: '$defaultApiBaseUrl/api/v1', connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20)));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    }, onError: (err, handler) async {
      if (err.response?.statusCode == 401) {
        await _storage.clearToken();
        _onUnauthorized?.call();
      }
      handler.next(err);
    }));
  }

  final AuthStorage _storage;
  final void Function()? _onUnauthorized;
  late final Dio dio;
}
