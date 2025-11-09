import 'package:hive/hive.dart';
part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isCompleted;

  @HiveField(2)
  String category;

  @HiveField(3)
  int priority;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  int orderIndex;

  Task({
    required this.title,
    this.isCompleted = false,
    required this.category,
    this.priority = 1,
    DateTime? createdAt,
    this.dueDate,
    this.orderIndex = 0,
  }) : createdAt = createdAt ?? DateTime.now();
}
