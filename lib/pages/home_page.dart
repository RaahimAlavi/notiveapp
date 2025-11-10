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
  // Make sure the order box is opened, use a late var
  late final Box<dynamic> _orderBox;

  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _filterCategory = 'All';
  SortOption _sortOption = SortOption.created;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Assign the opened box
    _orderBox = Hive.box('taskOrderBox');
    _syncOrderWithTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -----------------------------
  // Order box init & sync
  // -----------------------------

  Future<List<int>> _getSavedOrder() async {
    final raw = _orderBox.get('order');
    if (raw == null) return [];
    try {
      return (raw as List).map((e) => e as int).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _syncOrderWithTasks() async {
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

    await _orderBox.put('order', newOrder);
  }

  Future<void> _saveOrderList(List<int> newOrder) async {
    await _orderBox.put('order', newOrder);
  }

  // -----------------------------
  // Task CRUD
  // -----------------------------
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

    await _syncOrderWithTasks();

    // 2. FIX FOR CHECKBOX LAG
    // Add setState to force the HomePage to rebuild
    if (mounted) setState(() {});
  }

  Future<void> _deleteTask(Task task) async {
    await NotificationService.cancelNotification(task.key as int);
    final removedKey = task.key as int;
    await task.delete();

    final saved = await _getSavedOrder();
    final newOrder = saved.where((k) => k != removedKey).toList();
    await _saveOrderList(newOrder);

    await NotificationService.showInstantNotification(
      title: 'Task Deleted',
      body: 'Your task "${task.title}" has been removed.',
    );

    // 3. FIX FOR DELETE LAG
    // Add setState to force the HomePage to rebuild
    if (mounted) setState(() {});
  }

  // -----------------------------
  // Filtering & Sorting
  // -----------------------------
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
        final savedOrder = _orderBox.get('order') as List<int>? ?? [];
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

  // -----------------------------
  // Task Sheet (Add/Edit)
  // -----------------------------
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

    // Check if the current category still exists, if not, reset
    if (!availableCategories.contains(category) &&
        availableCategories.isNotEmpty) {
      category = availableCategories.first;
    } else if (availableCategories.isEmpty) {
      category = 'General';
    }

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
              // Re-fetch categories in case one was added/deleted
              final currentCategories = _getCategoryNames()
                  .where((c) => c != 'All')
                  .toList();
              if (!currentCategories.contains(category) &&
                  currentCategories.isNotEmpty) {
                category = currentCategories.first;
              } else if (currentCategories.isEmpty) {
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
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
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
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                    items: currentCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v ?? category),
                    hint: currentCategories.isEmpty
                        ? const Text('No categories (uses "General")')
                        : const Text('Select a category'),
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
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            final pickedTime = await showTimePicker(
                              context: context,
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

  // -----------------------------
  // Backup / Import helpers
  // -----------------------------
  Future<void> _doExport() async {
    try {
      // 4. FIX FOR BACKUP: Request permission first
      var status = await Permission.storage.request();

      // Handle new Android 13+ "granular" permissions
      if (Platform.isAndroid &&
          (await Permission.photos.isDenied ||
              await Permission.videos.isDenied ||
              await Permission.audio.isDenied)) {
        // This is a common workaround. Requesting a specific media type often
        // triggers the broader "Media" permission dialog.
        status = await Permission.photos.request();
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is permanently denied. Please enable it in app settings.',
              ),
            ),
          );
        }
        await openAppSettings();
        return;
      }

      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to export data.'),
            ),
          );
        }
        return;
      }

      // 5. FIX FOR BACKUP: Use a more reliable path
      Directory? downloadsDir;
      // 2. FIXED THE 'getExternalStoragePublicDirectory' ERROR
      // We will use getApplicationDocumentsDirectory for both platforms.
      // It's simpler, more reliable, and avoids many permission issues.
      downloadsDir = await getApplicationDocumentsDirectory();

      if (downloadsDir == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find Downloads directory.'),
            ),
          );
        }
        return;
      }

      final backupDir = Directory('${downloadsDir.path}/NotiveBackups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final jsonPath = await BackupService.exportTasksToJson();
      final srcFile = File(jsonPath);
      final destFile = File(
        '${backupDir.path}/notive_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await srcFile.copy(destFile.path);
      // Delete the temporary file
      await srcFile.delete();

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
      // 6. FIX FOR IMPORT: Request permission first
      var status = await Permission.storage.request();
      if (Platform.isAndroid &&
          (await Permission.photos.isDenied ||
              await Permission.videos.isDenied ||
              await Permission.audio.isDenied)) {
        status = await Permission.photos.request();
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is permanently denied. Please enable it in app settings.',
              ),
            ),
          );
        }
        await openAppSettings();
        return;
      }

      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to import data.'),
            ),
          );
        }
        return;
      }

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
      // Force refresh after import
      if (mounted) setState(() {});
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

  // -----------------------------
  // Main scaffold with bottom nav
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 3. Get the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // 4. THIS IS THE FULLY CORRECTED TABS LIST
    final tabs = <Widget>[
      // --- TasksTab ---
      TasksTab(
        taskBox: _taskBox,
        categoryBox: _categoryBox,
        // Pass the functions from this state
        getCategoryNames: _getCategoryNames,
        applyFiltersAndSort: _applyFiltersAndSort,
        toggleCompletion: _toggleCompletion,
        deleteTask: _deleteTask,
        showTaskSheet: ({Task? task}) => _showTaskSheet(task: task),
        getSavedOrder: _getSavedOrder,
        saveOrderList: _saveOrderList,
        initOrderBox: _syncOrderWithTasks, // Re-syncing is fine here
        // Pass the state values
        searchController: _searchController,
        filterCategory: _filterCategory,
        sortOption: _sortOption,
        query: _query,
        // Pass the state-setting callbacks
        onSearchChanged: (value) => setState(() => _query = value),
        onFilterChanged: (value) => setState(() => _filterCategory = value),
        onSortChanged: (value) => setState(() => _sortOption = value),
      ),
      // --- CompletedTab ---
      CompletedTab(
        taskBox: _taskBox,
        applyFiltersAndSort: _applyFiltersAndSort,
        toggleCompletion: _toggleCompletion,
        deleteTask: _deleteTask,
        showTaskSheet: ({Task? task}) => _showTaskSheet(task: task),
      ),
      // --- SettingsTab ---
      SettingsTab(
        // Get values from the theme provider
        isDarkMode: themeProvider.isDarkMode,
        onToggleTheme: themeProvider.toggleTheme,
        onChangeSeed: themeProvider.setSeedColor,
        // Pass backup functions
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
          // Theme toggle is now in SettingsTab
        ],
      ),
      body: SafeArea(
        // This is efficient! It just swaps which widget to show.
        // The ValueListenablBuilders *inside* the tabs will handle live updates.
        child: IndexedStack(index: _currentIndex, children: tabs),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      // This whole bottom part is rebuilt when _currentIndex changes
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
