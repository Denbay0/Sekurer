class TaskModel {
  final String id;
  final String callId;
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final bool requiresConfirmation;
  final String? sourceQuote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({required this.id, required this.callId, required this.userId, required this.title, this.description, this.dueDate, required this.priority, required this.status, required this.requiresConfirmation, this.sourceQuote, this.createdAt, this.updatedAt});

  factory TaskModel.fromJson(Map<String, dynamic> j) => TaskModel(
        id: j['id'].toString(),
        callId: j['call_id'].toString(),
        userId: j['user_id'].toString(),
        title: j['title'] as String,
        description: j['description'] as String?,
        dueDate: j['due_date'] != null ? DateTime.tryParse(j['due_date']) : null,
        priority: j['priority'].toString(),
        status: j['status'].toString(),
        requiresConfirmation: (j['requires_confirmation'] as bool?) ?? false,
        sourceQuote: j['source_quote'] as String?,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
        updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at']) : null,
      );
}
