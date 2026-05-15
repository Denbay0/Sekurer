import 'dart:io';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/call_models.dart';

class CallsApi {
  final ApiClient client;
  CallsApi(this.client);

  Future<List<CallListItem>> listCalls() async {
    final res = await client.dio.get('/calls');
    return (res.data as List).map((e) => CallListItem.fromJson(e)).toList();
  }

  Future<String> uploadCall(File file, {String? title, String? contactName, String? phoneNumber}) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last), 'title': title, 'contact_name': contactName, 'phone_number': phoneNumber});
    final res = await client.dio.post('/calls/upload', data: form);
    return res.data['id'].toString();
  }

  Future<CallDetail> getCall(String id) async => CallDetail.fromJson((await client.dio.get('/calls/$id')).data);
  Future<void> retry(String id) async => client.dio.post('/calls/$id/retry');
}
