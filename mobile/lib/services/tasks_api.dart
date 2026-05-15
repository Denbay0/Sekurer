import '../core/api_client.dart';
import '../models/task_models.dart';

class TasksApi {
  final ApiClient client;
  TasksApi(this.client);

  Future<List<TaskModel>> listTasks() async {
    final res = await client.dio.get('/tasks');
    return (res.data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<TaskModel> updateTask(String taskId, Map<String, dynamic> payload) async {
    final res = await client.dio.patch('/tasks/$taskId', data: payload);
    return TaskModel.fromJson(res.data);
  }
}
