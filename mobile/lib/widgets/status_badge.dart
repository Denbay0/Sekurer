import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final map = {'uploaded':'Загружен','transcribing':'Расшифровка','analyzing':'Анализ','ready':'Готово','failed':'Ошибка'};
    final colors = {'uploaded':Colors.blue,'transcribing':Colors.orange,'analyzing':Colors.deepOrange,'ready':Colors.green,'failed':Colors.red};
    return Chip(label: Text(map[status] ?? status), backgroundColor: (colors[status] ?? Colors.grey).withValues(alpha: 0.15));
  }
}
