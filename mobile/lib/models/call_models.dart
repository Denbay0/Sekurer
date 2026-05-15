import 'calendar_item_models.dart';
import 'task_models.dart';

class CallListItem {
  final String id;
  final String? title;
  final String? contactName;
  final String? phoneNumber;
  final String status;
  final DateTime createdAt;
  final DateTime? processedAt;

  CallListItem({required this.id, this.title, this.contactName, this.phoneNumber, required this.status, required this.createdAt, this.processedAt});

  factory CallListItem.fromJson(Map<String, dynamic> j) => CallListItem(
        id: j['id'].toString(),
        title: j['title'] as String?,
        contactName: j['contact_name'] as String?,
        phoneNumber: j['phone_number'] as String?,
        status: j['status'].toString(),
        createdAt: DateTime.parse(j['created_at']),
        processedAt: j['processed_at'] != null ? DateTime.tryParse(j['processed_at']) : null,
      );
}

class Agreement {
  final String id;
  final String callId;
  final String text;
  final String owner;
  final DateTime? deadline;
  final double? confidence;
  final String? sourceQuote;

  Agreement({required this.id, required this.callId, required this.text, required this.owner, this.deadline, this.confidence, this.sourceQuote});

  factory Agreement.fromJson(Map<String, dynamic> j) => Agreement(
        id: j['id'].toString(),
        callId: j['call_id'].toString(),
        text: j['text'] as String,
        owner: j['owner'].toString(),
        deadline: j['deadline'] != null ? DateTime.tryParse(j['deadline']) : null,
        confidence: (j['confidence'] as num?)?.toDouble(),
        sourceQuote: j['source_quote'] as String?,
      );
}

class UnclearPoint {
  final String id;
  final String callId;
  final String text;

  UnclearPoint({required this.id, required this.callId, required this.text});

  factory UnclearPoint.fromJson(Map<String, dynamic> j) => UnclearPoint(id: j['id'].toString(), callId: j['call_id'].toString(), text: j['text'] as String);
}

class CallDetail extends CallListItem {
  final String? audioOriginalFilename;
  final String? audioContentType;
  final int? audioSizeBytes;
  final String? transcript;
  final String? summary;
  final String? errorMessage;
  final List<Agreement> agreements;
  final List<TaskModel> tasks;
  final List<CalendarItemModel> calendarItems;
  final List<UnclearPoint> unclearPoints;

  CallDetail({required super.id, super.title, super.contactName, super.phoneNumber, required super.status, required super.createdAt, super.processedAt, this.audioOriginalFilename, this.audioContentType, this.audioSizeBytes, this.transcript, this.summary, this.errorMessage, required this.agreements, required this.tasks, required this.calendarItems, required this.unclearPoints});

  factory CallDetail.fromJson(Map<String, dynamic> j) => CallDetail(
        id: j['id'].toString(),
        title: j['title'] as String?,
        contactName: j['contact_name'] as String?,
        phoneNumber: j['phone_number'] as String?,
        status: j['status'].toString(),
        createdAt: DateTime.parse(j['created_at']),
        processedAt: j['processed_at'] != null ? DateTime.tryParse(j['processed_at']) : null,
        audioOriginalFilename: j['audio_original_filename'] as String?,
        audioContentType: j['audio_content_type'] as String?,
        audioSizeBytes: j['audio_size_bytes'] as int?,
        transcript: j['transcript'] as String?,
        summary: j['summary'] as String?,
        errorMessage: j['error_message'] as String?,
        agreements: ((j['agreements'] as List?) ?? []).map((e) => Agreement.fromJson(e)).toList(),
        tasks: ((j['tasks'] as List?) ?? []).map((e) => TaskModel.fromJson(e)).toList(),
        calendarItems: ((j['calendar_items'] as List?) ?? []).map((e) => CalendarItemModel.fromJson(e)).toList(),
        unclearPoints: ((j['unclear_points'] as List?) ?? []).map((e) => UnclearPoint.fromJson(e)).toList(),
      );
}
