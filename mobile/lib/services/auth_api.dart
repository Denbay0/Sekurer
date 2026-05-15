import '../core/api_client.dart';
import '../models/auth_models.dart';

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  Future<TokenResponse> login(LoginRequest req) async {
    final res = await client.dio.post('/auth/login', data: req.toJson());
    return TokenResponse.fromJson(res.data);
  }

  Future<void> register(RegisterRequest req) async {
    await client.dio.post('/auth/register', data: req.toJson());
  }
}
