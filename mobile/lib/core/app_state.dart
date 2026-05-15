import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/auth_api.dart';
import 'api_client.dart';
import 'auth_storage.dart';

class AppState extends ChangeNotifier {
  AppState({AuthStorage? storage, ApiClient? apiClient})
      : storage = storage ?? AuthStorage(),
        api = apiClient;

  final AuthStorage storage;
  ApiClient? api;
  String? token;
  bool loading = true;

  ApiClient get client => api ??= ApiClient(storage, onUnauthorized: logout);

  Future<void> init() async {
    api ??= ApiClient(storage, onUnauthorized: logout);
    token = await storage.getToken();
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final t = await AuthApi(client).login(
      LoginRequest(email: email, password: password),
    );
    await storage.saveToken(t.accessToken);
    token = t.accessToken;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final t = await AuthApi(client).register(
      RegisterRequest(name: name, email: email, password: password),
    );
    await storage.saveToken(t.accessToken);
    token = t.accessToken;
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.clearToken();
    token = null;
    notifyListeners();
  }
}
