import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notiveapp/models/category_model.dart';

class CategoryManagementPage extends StatelessWidget {
  CategoryManagementPage({super.key});

  final Box<Category> _categoryBox = Hive.box<Category>('categoriesBox');
  final TextEditingController _controller = TextEditingController();

  // CRUD Logic
  void _addCategory(BuildContext context) {
    if (_controller.text.trim().isEmpty) return;

    // Check category if already exists (case-insensitive)
    final existingNames = _categoryBox.values
        .map((c) => c.name.toLowerCase())
        .toSet();
    if (existingNames.contains(_controller.text.trim().toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Category "${_controller.text.trim()}" already exists.',
          ),
        ),
      );
      _controller.clear();
      return;
    }

    final newCategory = Category(name: _controller.text.trim());
    _categoryBox.add(newCategory);
    _controller.clear();
    Navigator.pop(context);
  }

  void _deleteCategory(Category category, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete the category "${category.name}"? This will NOT delete associated tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              category.delete();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // UI Helper
  Future<void> _showAddCategoryDialog(BuildContext context) async {
    _controller.clear();
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Category name (e.g., Shopping)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _addCategory(context),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add Category'),
      ),
      body: ValueListenableBuilder<Box<Category>>(
        valueListenable: _categoryBox.listenable(),
        builder: (context, box, _) {
          final categories = box.values.toList();

          return ListView.separated(
            itemCount: categories.length,
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: Icon(
                  Icons.folder_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(category.name),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _deleteCategory(category, context),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
