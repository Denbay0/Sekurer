import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_state.dart';
import '../../models/call_models.dart';
import '../../services/calendar_items_api.dart';
import '../../services/calls_api.dart';
import '../../services/tasks_api.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';

class CallDetailScreen extends StatefulWidget {
  const CallDetailScreen({super.key, required this.callId});

  final String callId;

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  CallDetail? d;
  Timer? timer;
  String? err;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool _shouldPoll(String status) {
    return ['uploaded', 'transcribing', 'analyzing'].contains(status);
  }

  void _ensurePolling() {
    timer ??= Timer.periodic(const Duration(seconds: 2), (_) => load());
  }

  void _stopPolling() {
    timer?.cancel();
    timer = null;
  }

  Future<void> load() async {
    try {
      d = await CallsApi(context.read<AppState>().client).getCall(widget.callId);
      err = null;
      if (_shouldPoll(d!.status)) {
        _ensurePolling();
      } else {
        _stopPolling();
      }
    } catch (e) {
      err = getApiErrorMessage(e);
      _stopPolling();
    }
    if (mounted) setState(() {});
  }

  Future<void> retryProcessing() async {
    await CallsApi(context.read<AppState>().client).retry(widget.callId);
    _stopPolling();
    await load();
  }

  Future<void> updTask(String id, Map<String, dynamic> payload) async {
    await TasksApi(context.read<AppState>().client).updateTask(id, payload);
    await load();
  }

  Future<void> updEvent(String id, Map<String, dynamic> payload) async {
    await CalendarItemsApi(context.read<AppState>().client)
        .updateCalendarItem(id, payload);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Детали звонка')),
      body: err != null
          ? ErrorView(message: err!, onRetry: load)
          : d == null
              ? const LoadingView()
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Text(
                      d!.title ?? 'Без названия',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(d!.contactName ?? '—'),
                    Text(d!.phoneNumber ?? '—'),
                    StatusBadge(status: d!.status),
                    Text(
                      'Создан: ${DateFormat('dd.MM.yyyy HH:mm').format(d!.createdAt.toLocal())}',
                    ),
                    if (d!.processedAt != null)
                      Text(
                        'Обработан: ${DateFormat('dd.MM.yyyy HH:mm').format(d!.processedAt!.toLocal())}',
                      ),
                    if (d!.status == 'uploaded') const Text('Файл загружен'),
                    if (d!.status == 'transcribing')
                      const Text('Идёт расшифровка'),
                    if (d!.status == 'analyzing')
                      const Text('Идёт анализ договорённостей'),
                    if (d!.status == 'failed') ...[
                      Text(d!.errorMessage ?? 'Ошибка обработки'),
                      ElevatedButton(
                        onPressed: retryProcessing,
                        child: const Text('Повторить обработку'),
                      ),
                    ],
                    Card(
                      child: ListTile(
                        title: const Text('Кратко'),
                        subtitle: Text(d!.summary ?? 'Нет краткого описания'),
                      ),
                    ),
                    ...d!.agreements.map(
                      (a) => Card(
                        child: ListTile(
                          title: Text(a.text),
                          subtitle: Text(
                            'Ответственный: ${a.owner}\n'
                            'Срок: ${a.deadline?.toIso8601String() ?? '—'}\n'
                            'Уверенность: ${a.confidence?.toStringAsFixed(2) ?? '—'}\n'
                            'Цитата: ${a.sourceQuote ?? '—'}',
                          ),
                        ),
                      ),
                    ),
                    ...d!.tasks.map(
                      (t) => Card(
                        child: ListTile(
                          title: Text(t.title),
                          subtitle: Text(
                            '${t.description ?? ''}\n${t.status} • ${t.priority}\n${t.sourceQuote ?? ''}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () => updTask(t.id, {
                                  'status': 'confirmed',
                                  'requires_confirmation': false,
                                }),
                                child: const Text('Подтвердить'),
                              ),
                              TextButton(
                                onPressed: () => updTask(t.id, {'status': 'done'}),
                                child: const Text('Выполнено'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    updTask(t.id, {'status': 'cancelled'}),
                                child: const Text('Отменить'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    ...d!.calendarItems.map(
                      (e) => Card(
                        child: ListTile(
                          title: Text(e.title),
                          subtitle: Text(
                            '${e.description ?? ''}
${e.status} ${e.requiresConfirmation ? '(требует подтверждения)' : ''}',
                          ),
                          trailing: Wrap(
                            children: [
                              TextButton(
                                onPressed: () => updEvent(e.id, {
                                  'status': 'confirmed',
                                  'requires_confirmation': false,
                                }),
                                child: const Text('Подтвердить'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    updEvent(e.id, {'status': 'cancelled'}),
                                child: const Text('Отменить'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Неясности'),
                            ...d!.unclearPoints.map((u) => Text('• ${u.text}')),
                          ],
                        ),
                      ),
                    ),
                    ExpansionTile(
                      title: const Text('Транскрипт'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(d!.transcript ?? 'Транскрипт пока недоступен'),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
