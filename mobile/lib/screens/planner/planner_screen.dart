import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/api_client.dart';
import '../../models/task_models.dart';
import '../../services/tasks_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  List<TaskModel>? tasks;
  String? error;
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      tasks = await TasksApi(context.read<AppState>().client).listTasks();
      error = null;
    } catch (e) {
      error = getApiErrorMessage(e);
    }
    if (mounted) setState(() {});
  }

  bool isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    if (tasks == null && error == null) {
      return const LoadingView();
    }
    if (error != null) {
      return ErrorView(message: error!, onRetry: load);
    }

    final data = tasks!.where((x) {
      if (filter == 'draft') return x.status == 'draft';
      if (filter == 'confirmed') return x.status == 'confirmed';
      if (filter == 'done') return x.status == 'done';
      return true;
    }).toList();

    final done = data.where((e) => e.status == 'done').toList();
    final noDue =
        data.where((e) => e.status != 'done' && e.dueDate == null).toList();
    final today = data
        .where((e) => e.status != 'done' && e.dueDate != null && isToday(e.dueDate!))
        .toList();
    final tomorrow = data
        .where(
          (e) =>
              e.status != 'done' &&
              e.dueDate != null &&
              isToday(e.dueDate!.subtract(const Duration(days: 1))),
        )
        .toList();
    final later = data
        .where(
          (e) =>
              e.status != 'done' &&
              e.dueDate != null &&
              !today.contains(e) &&
              !tomorrow.contains(e),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (final e in const {
                'all': 'Все',
                'draft': 'Черновики',
                'confirmed': 'Подтверждённые',
                'done': 'Выполненные',
              }.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: filter == e.key,
                  onSelected: (_) => setState(() => filter = e.key),
                ),
            ],
          ),
          if (data.isEmpty)
            const EmptyState(
              title: 'Нет задач',
              subtitle: 'Задачи появятся после анализа звонка',
            ),
          _group(context, 'Сегодня', today),
          _group(context, 'Завтра', tomorrow),
          _group(context, 'Позже', later),
          _group(context, 'Без срока', noDue),
          _group(context, 'Выполненные', done),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<TaskModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...items.map(_card),
      ],
    );
  }

  Widget _card(TaskModel task) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Text(
          '${task.dueDate?.toIso8601String().split('T').first ?? 'без срока'} • '
          '${task.priority} • ${task.status}'
          '${task.sourceQuote != null ? '\n${task.sourceQuote}' : ''}',
        ),
        trailing: Wrap(
          children: [
            TextButton(
              onPressed: () => upd(task.id, {
                'status': 'confirmed',
                'requires_confirmation': false,
              }),
              child: const Text('Подтвердить'),
            ),
            TextButton(
              onPressed: () => upd(task.id, {'status': 'done'}),
              child: const Text('Выполнено'),
            ),
            TextButton(
              onPressed: () => upd(task.id, {'status': 'cancelled'}),
              child: const Text('Отменить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> upd(String id, Map<String, dynamic> payload) async {
    await TasksApi(context.read<AppState>().client).updateTask(id, payload);
    await load();
  }
}
