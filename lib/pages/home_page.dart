import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:notiveapp/models/task_model.dart';
import 'package:notiveapp/models/category_model.dart';
import 'package:notiveapp/pages/category_management_page.dart';
import 'package:notiveapp/pages/completed_tab.dart';
import 'package:notiveapp/pages/settings_tab.dart';
import 'package:notiveapp/pages/task_tab.dart';
import 'package:notiveapp/services/backup_service.dart';
import 'package:notiveapp/services/notifications_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:notiveapp/util/theme_provider.dart';

enum SortOption { created, dueDate, priority, title, custom }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box<Task> _taskBox = Hive.box<Task>('tasksBox');
  final Box<Category> _categoryBox = Hive.box<Category>('categoriesBox');
  Box<dynamic>? _orderBox;

  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _filterCategory = 'All';
  SortOption _sortOption = SortOption.created;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _initOrderBox();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Order box sync
  Future<void> _initOrderBox() async {
    if (!Hive.isBoxOpen('taskOrderBox')) {
      await Hive.openBox('taskOrderBox');
    }
    _orderBox = Hive.box('taskOrderBox');
    await _syncOrderWithTasks();
    if (mounted) setState(() {});
  }

  Future<List<int>> _getSavedOrder() async {
    if (_orderBox == null) return [];
    final raw = _orderBox!.get('order');
    if (raw == null) return [];
    try {
      return (raw as List).map((e) => e as int).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _syncOrderWithTasks() async {
    if (_orderBox == null) return;

    final currentIncompleteKeys = _taskBox.keys
        .where((k) {
          final t = _taskBox.get(k);
          return t != null && !t.isCompleted;
        })
        .map((k) => k as int)
        .toList();

    final saved = await _getSavedOrder();

    final pruned = saved
        .where((k) => currentIncompleteKeys.contains(k))
        .toList();

    final missing = currentIncompleteKeys
        .where((k) => !pruned.contains(k))
        .toList();
    final newOrder = [...pruned, ...missing];

    await _orderBox!.put('order', newOrder);
  }

  Future<void> _saveOrderList(List<int> newOrder) async {
    if (_orderBox == null) {
      await _initOrderBox();
    }
    await _orderBox!.put('order', newOrder);
  }

  // Task CRUD
  Future<void> _addOrUpdateTask({
    Task? existing,
    required String title,
    required String category,
    DateTime? dueDate,
    required int priority,
  }) async {
    int? taskId;

    if (existing != null) {
      taskId = existing.key as int?;
      existing.title = title;
      existing.category = category;
      existing.dueDate = dueDate;
      existing.priority = priority;
      await existing.save();

      if (taskId != null) await NotificationService.cancelNotification(taskId);
    } else {
      final newTask = Task(
        title: title,
        category: category,
        dueDate: dueDate,
        priority: priority,
      );
      taskId = await _taskBox.add(newTask);
    }

    if (dueDate != null && taskId != null) {
      await NotificationService.scheduleNotification(
        id: taskId,
        title: title,
        body: 'Reminder: $title is due soon!',
        dateTime: dueDate,
      );
    }

    // Keep order box in sync new task will be append
    await _syncOrderWithTasks();
    if (mounted) setState(() {});
  }

  Future<void> _toggleCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    await task.save();

    if (task.isCompleted) {
      if (task.key != null) {
        await NotificationService.cancelNotification(task.key as int);
      }
      await NotificationService.showInstantNotification(
        title: 'Task Completed!',
        body: 'Great job completing "${task.title}".',
      );
    } else if (task.dueDate != null) {
      await NotificationService.scheduleNotification(
        id: task.key as int,
        title: task.title,
        body: 'Reminder: ${task.title} is due soon!',
        dateTime: task.dueDate!,
      );
    }

    // Update order
    await _syncOrderWithTasks();

    if (mounted) setState(() {});
  }

  Future<void> _deleteTask(Task task) async {
    await NotificationService.cancelNotification(task.key as int);
    final removedKey = task.key as int;
    await task.delete();

    // remove from saved order
    if (_orderBox != null) {
      final saved = await _getSavedOrder();
      final newOrder = saved.where((k) => k != removedKey).toList();
      await _saveOrderList(newOrder);
    }

    await NotificationService.showInstantNotification(
      title: 'Task Deleted',
      body: 'Your task "${task.title}" has been removed.',
    );

    if (mounted) setState(() {});
  }

  // Sorting
  List<String> _getCategoryNames() {
    final categoryNames = _categoryBox.values.map((c) => c.name).toList();
    return ['All', ...categoryNames];
  }

  List<Task> _applyFiltersAndSort(List<Task> tasks) {
    var list = tasks;

    if (_filterCategory != 'All') {
      list = list.where((t) => t.category == _filterCategory).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_sortOption) {
      case SortOption.created:
        // newest first
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dueDate:
        list.sort((a, b) {
          final aDate = a.dueDate ?? DateTime(2100);
          final bDate = b.dueDate ?? DateTime(2100);
          return aDate.compareTo(bDate);
        });
        break;
      case SortOption.priority:
        list.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case SortOption.title:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.custom:
        final savedOrder =
            (_orderBox?.get('order') as List?)?.cast<int>() ?? [];
        if (savedOrder.isNotEmpty) {
          final map = {for (var t in list) (t.key as int): t};
          final ordered = <Task>[];
          for (final k in savedOrder) {
            if (map.containsKey(k)) ordered.add(map[k]!);
          }
          for (final t in list) {
            if (!savedOrder.contains(t.key as int)) ordered.add(t);
          }
          list = ordered;
        }
        break;
    }

    return list;
  }

  // Task Sheet (Add/Edit)
  Future<void> _showTaskSheet({Task? task}) async {
    final availableCategories = _getCategoryNames()
        .where((c) => c != 'All')
        .toList();
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    String category =
        task?.category ??
        (availableCategories.isNotEmpty
            ? availableCategories.first
            : 'General');
    DateTime? due = task?.dueDate;
    int priority = task?.priority ?? 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 18,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final colorScheme = Theme.of(context).colorScheme;
              final currentCategories = _getCategoryNames()
                  .where((c) => c != 'All')
                  .toList();
              if (!currentCategories.contains(category) &&
                  currentCategories.isNotEmpty) {
                category = currentCategories.first;
              } else if (currentCategories.isEmpty && category.isEmpty) {
                category = 'General';
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task == null ? 'Add Task' : 'Edit Task',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: currentCategories.contains(category)
                        ? category
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    items: currentCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v ?? category),
                    hint: currentCategories.isEmpty
                        ? const Text('No categories')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          due != null
                              ? 'Due: ${DateFormat.yMd().add_jm().format(due ?? DateTime.now())}'
                              : 'No due date',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: due ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            final pickedTime = await showTimePicker(
                              context: context,
                              // make sure a non-null DateTime is given
                              initialTime: TimeOfDay.fromDateTime(
                                due ?? DateTime.now(),
                              ),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                due = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        child: const Text('Set Due'),
                      ),
                      if (due != null)
                        TextButton(
                          onPressed: () => setState(() => due = null),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Priority:'),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: priority,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Low')),
                          DropdownMenuItem(value: 1, child: Text('Medium')),
                          DropdownMenuItem(value: 2, child: Text('High')),
                        ],
                        onChanged: (v) =>
                            setState(() => priority = v ?? priority),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          await _addOrUpdateTask(
                            existing: task,
                            title: titleCtrl.text.trim(),
                            category: category,
                            dueDate: due,
                            priority: priority,
                          );
                          Navigator.pop(context);
                        },
                        child: Text(task == null ? 'Add Task' : 'Update Task'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Backup / Import helpers
  Future<void> _doExport() async {
    try {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Request permissions for Android
        if (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted) {
          downloadsDir = Directory(
            '/storage/emulated/0/Download/NotiveBackups',
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission denied. Cannot export.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final jsonPath = await BackupService.exportTasksToJson();
      final srcFile = File(jsonPath);
      final destFile = File(
        '${downloadsDir.path}/notive_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await srcFile.copy(destFile.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to: ${destFile.path}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _doImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path!;
      final addedCount = await BackupService.importFromJsonFile(filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import successful! $addedCount tasks restored.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _syncOrderWithTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed. Ensure it is a valid Notive JSON: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Main scaffold
  @override
  Widget build(BuildContext context) {
    // Get the theme
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cs = Theme.of(context).colorScheme;

    final tabs = <Widget>[
      // Tasks tab
      TasksTab(
        taskBox: _taskBox,
        categoryBox: _categoryBox,
        getCategoryNames: _getCategoryNames,
        applyFiltersAndSort: _applyFiltersAndSort,
        toggleCompletion: _toggleCompletion,
        deleteTask: _deleteTask,
        showTaskSheet: _showTaskSheet,
        getSavedOrder: _getSavedOrder,
        saveOrderList: _saveOrderList,
        initOrderBox: _initOrderBox,
        searchController: _searchController,
        filterCategory: _filterCategory,
        sortOption: _sortOption,
        query: _query,
        onSearchChanged: (v) => setState(() => _query = v),
        onFilterChanged: (c) => setState(() => _filterCategory = c),
        onSortChanged: (o) => setState(() => _sortOption = o),
      ),

      // Completed tab
      CompletedTab(
        taskBox: _taskBox,
        applyFiltersAndSort: _applyFiltersAndSort,
        toggleCompletion: _toggleCompletion,
        deleteTask: _deleteTask,
        showTaskSheet: _showTaskSheet,
      ),

      // Settings tab
      SettingsTab(
        isDarkMode: themeProvider.isDarkMode,
        onToggleTheme: themeProvider.toggleTheme,
        onChangeSeed: themeProvider.setSeedColor,
        doExport: _doExport,
        doImport: _doImport,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notive'),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          IconButton(
            tooltip: 'Export backup',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _doExport,
          ),
          IconButton(
            tooltip: 'Import backup',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _doImport,
          ),
          IconButton(
            // Use theme provider to build the icon and action
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: SafeArea(child: tabs[_currentIndex]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            label: 'Completed',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
