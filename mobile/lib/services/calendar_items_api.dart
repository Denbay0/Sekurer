import '../core/api_client.dart';
import '../models/calendar_item_models.dart';

class CalendarItemsApi {
  final ApiClient client;
  CalendarItemsApi(this.client);

  Future<List<CalendarItemModel>> listItems() async {
    final res = await client.dio.get('/calendar-items');
    return (res.data as List).map((e) => CalendarItemModel.fromJson(e)).toList();
  }
}
