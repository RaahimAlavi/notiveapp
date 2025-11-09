import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ToDoTile extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final String category;
  final int priority;
  final DateTime? dueDate;
  final bool isDarkMode;
  final Function(bool?) onChanged;
  final Function(BuildContext) deleteFunction;
  final VoidCallback onEdit;

  const ToDoTile({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.isDarkMode,
    required this.onChanged,
    required this.deleteFunction,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = switch (priority) {
      2 => cs.error,
      1 => cs.tertiary,
      _ => cs.outlineVariant,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      color: cs.surfaceContainerHigh,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Chip(
                          label: Text(category),
                          labelStyle: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                          backgroundColor: cs.surfaceContainerLow,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        if (dueDate != null)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: cs.outline,
                              ),

                              const SizedBox(width: 2),
                              Text(
                                DateFormat.MMMd().add_jm().format(dueDate!),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: cs.onSurface),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.flag, color: priorityColor, size: 20),
                tooltip: 'Priority',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: cs.outline,
                tooltip: 'Delete',
                onPressed: () => deleteFunction(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
