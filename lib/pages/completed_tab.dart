import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notiveapp/models/task_model.dart';
import 'package:notiveapp/util/todo_tile.dart';

class CompletedTab extends StatelessWidget {
  // Boxes
  final Box<Task> taskBox;

  // Logic Functions
  final List<Task> Function(List<Task>) applyFiltersAndSort;
  final Future<void> Function(Task) toggleCompletion;
  final Future<void> Function(Task) deleteTask;
  final Future<void> Function({Task? task}) showTaskSheet;

  const CompletedTab({
    super.key,
    required this.taskBox,
    required this.applyFiltersAndSort,
    required this.toggleCompletion,
    required this.deleteTask,
    required this.showTaskSheet,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Box<Task>>(
      valueListenable: taskBox.listenable(),
      builder: (context, box, _) {
        final completed = box.values.where((t) => t.isCompleted).toList();
        final tasks = applyFiltersAndSort(completed);

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 64,
                  color: cs.primary.withOpacity(0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  'No completed tasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete a task to see it here',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 90, top: 6),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final t = tasks[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ToDoTile(
                title: t.title,
                isCompleted: t.isCompleted,
                category: t.category,
                priority: t.priority,
                dueDate: t.dueDate,
                isDarkMode: Theme.of(context).brightness == Brightness.dark,
                onChanged: (_) => toggleCompletion(t),
                deleteFunction: (_) => deleteTask(t),
                onEdit: () => showTaskSheet(task: t),
              ),
            );
          },
        );
      },
    );
  }
}
