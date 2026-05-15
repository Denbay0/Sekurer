import 'dart:io';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/call_models.dart';

class CallsApi {
  final ApiClient client;
  CallsApi(this.client);

  Future<List<CallListItem>> listCalls() async {
    final res = await client.dio.get('/calls');
    return (res.data as List)
        .map((e) => CallListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadCall(
    File file, {
    String? title,
    String? contactName,
    String? phoneNumber,
  }) async {
    final map = <String, dynamic>{
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    };

    if (title != null && title.trim().isNotEmpty) map['title'] = title.trim();
    if (contactName != null && contactName.trim().isNotEmpty) {
      map['contact_name'] = contactName.trim();
    }
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      map['phone_number'] = phoneNumber.trim();
    }

    final form = FormData.fromMap(map);
    final res = await client.dio.post('/calls/upload', data: form);
    return res.data['id'].toString();
  }

  Future<CallDetail> getCall(String id) async {
    return CallDetail.fromJson(
      (await client.dio.get('/calls/$id')).data as Map<String, dynamic>,
    );
  }

  Future<void> retry(String id) async => client.dio.post('/calls/$id/retry');
}
