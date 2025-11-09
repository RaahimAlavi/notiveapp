import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:notiveapp/models/task_model.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static Future<String> exportTasksToJson() async {
    final box = Hive.box<Task>('tasksBox');
    final tasks = box.values
        .map(
          (t) => {
            'title': t.title,
            'category': t.category,
            'isCompleted': t.isCompleted,
            'priority': t.priority,
            'dueDate': t.dueDate?.toIso8601String(),
            'createdAt': t.createdAt.toIso8601String(),
            'notifId': t.key,
          },
        )
        .toList();

    final jsonStr = jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks,
    });

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/NotiveBackups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File(
      '${backupDir.path}/notive_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    await file.writeAsString(jsonStr);
    return file.path;
  }

  static Future<int> importFromJsonFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final tasksJson = (json['tasks'] as List).cast<Map<String, dynamic>>();

    final box = Hive.box<Task>('tasksBox');
    int added = 0;
    for (final t in tasksJson) {
      final task = Task(
        title: t['title'] ?? '',
        category: t['category'] ?? 'General',
        isCompleted: t['isCompleted'] ?? false,
        priority: (t['priority'] is int) ? t['priority'] : 1,
        dueDate: t['dueDate'] != null ? DateTime.tryParse(t['dueDate']) : null,
        createdAt: t['createdAt'] != null
            ? DateTime.parse(t['createdAt'])
            : DateTime.now(),
      );
      await box.add(task);
      added++;
    }
    return added;
  }
}
