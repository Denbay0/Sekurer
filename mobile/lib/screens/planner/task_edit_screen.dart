import 'package:flutter/material.dart';

class TaskEditScreen extends StatelessWidget {
  const TaskEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование задачи')),
      body: const Center(child: Text('Редактирование задачи будет добавлено позже.')),
    );
  }
}
