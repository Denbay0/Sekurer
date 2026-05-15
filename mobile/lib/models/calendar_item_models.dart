class CalendarItemModel {
  final String id;
  final String callId;
  final String userId;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final bool requiresConfirmation;

  CalendarItemModel({required this.id, required this.callId, required this.userId, required this.title, this.description, this.startTime, this.endTime, required this.status, required this.requiresConfirmation});

  factory CalendarItemModel.fromJson(Map<String, dynamic> j) => CalendarItemModel(
        id: j['id'].toString(),
        callId: j['call_id'].toString(),
        userId: j['user_id'].toString(),
        title: j['title'] as String,
        description: j['description'] as String?,
        startTime: j['start_time'] != null ? DateTime.tryParse(j['start_time']) : null,
        endTime: j['end_time'] != null ? DateTime.tryParse(j['end_time']) : null,
        status: j['status'].toString(),
        requiresConfirmation: (j['requires_confirmation'] as bool?) ?? false,
      );
}
