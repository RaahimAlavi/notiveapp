import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notiveapp/models/category_model.dart';
import 'package:notiveapp/models/task_model.dart';
import 'package:notiveapp/pages/home_page.dart';
import 'package:notiveapp/util/todo_tile.dart';

class TasksTab extends StatelessWidget {
  // Boxes
  final Box<Task> taskBox;
  final Box<Category> categoryBox;

  // Logic Functions
  final List<String> Function() getCategoryNames;
  final List<Task> Function(List<Task>) applyFiltersAndSort;
  final Future<void> Function(Task) toggleCompletion;
  final Future<void> Function(Task) deleteTask;
  final Future<void> Function({Task? task}) showTaskSheet;
  final Future<List<int>> Function() getSavedOrder;
  final Future<void> Function(List<int>) saveOrderList;
  final Future<void> Function() initOrderBox;

  // State properties from HomePage
  final TextEditingController searchController;
  final String filterCategory;
  final SortOption sortOption;
  final String query;

  // State change callbacks
  final void Function(String) onSearchChanged;
  final void Function(String) onFilterChanged;
  final void Function(SortOption) onSortChanged;

  const TasksTab({
    super.key,
    required this.taskBox,
    required this.categoryBox,
    required this.getCategoryNames,
    required this.applyFiltersAndSort,
    required this.toggleCompletion,
    required this.deleteTask,
    required this.showTaskSheet,
    required this.getSavedOrder,
    required this.saveOrderList,
    required this.initOrderBox,
    required this.searchController,
    required this.filterCategory,
    required this.sortOption,
    required this.query,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  Widget _buildTaskList(BuildContext context, List<Task> filtered) {
    final bool allowReorder =
        (query.isEmpty &&
        filterCategory == 'All' &&
        sortOption == SortOption.custom);

    if (filtered.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: cs.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a new task or check your filters',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      );
    }

    if (allowReorder) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 90, top: 6),
        itemCount: filtered.length,
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex -= 1;

          final savedOrder = (await getSavedOrder()).toList();
          final movedTaskId = filtered[oldIndex].key as int;

          if (!savedOrder.contains(movedTaskId)) {
            final base = filtered.map((t) => t.key as int).toList();
            savedOrder.clear();
            savedOrder.addAll(base);
          }

          savedOrder.remove(movedTaskId);
          savedOrder.insert(newIndex, movedTaskId);
          await saveOrderList(savedOrder);
        },
        itemBuilder: (context, index) {
          final t = filtered[index];
          return Padding(
            key: ValueKey(t.key),
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
    }

    // Normal list
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 90, top: 6),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final t = filtered[index];
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
  }

  @override
  Widget build(BuildContext context) {
    // We show incomplete tasks in the main tab
    final allTasks = taskBox.values.toList();
    var incompleteTasks = allTasks.where((t) => !t.isCompleted).toList();
    // apply filters and sort
    var filtered = applyFiltersAndSort(incompleteTasks);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search tasks',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<SortOption>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort_rounded),
                onSelected: onSortChanged,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SortOption.created,
                    child: Text('Sort by Created'),
                  ),
                  PopupMenuItem(
                    value: SortOption.dueDate,
                    child: Text('Sort by Due Date'),
                  ),
                  PopupMenuItem(
                    value: SortOption.priority,
                    child: Text('Sort by Priority'),
                  ),
                  PopupMenuItem(
                    value: SortOption.title,
                    child: Text('Sort by Title'),
                  ),
                  PopupMenuItem(
                    value: SortOption.custom,
                    child: Text('Custom Order (drag to reorder)'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ValueListenableBuilder<Box<Category>>(
            valueListenable: categoryBox.listenable(),
            builder: (context, box, child) {
              final categoryList = getCategoryNames();
              final cs = Theme.of(context).colorScheme;

              // Safely reset filter if current one was deleted
              if (filterCategory != 'All' &&
                  !categoryList.contains(filterCategory)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onFilterChanged('All');
                });
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeInOut,
                child: ListView.separated(
                  key: ValueKey(categoryList.join(',')),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  itemCount: categoryList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final c = categoryList[idx];
                    final selected = filterCategory == c;

                    return ChoiceChip(
                      label: Text(c, overflow: TextOverflow.ellipsis),
                      selected: selected,
                      onSelected: (_) => onFilterChanged(c),
                      selectedColor: cs.primaryContainer,
                      labelStyle: TextStyle(
                        color: selected ? cs.onPrimaryContainer : cs.onSurface,
                      ),
                      backgroundColor: cs.surfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Expanded list area
        Expanded(child: _buildTaskList(context, filtered)),
      ],
    );
  }
}
