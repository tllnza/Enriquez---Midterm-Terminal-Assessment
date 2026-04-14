import 'package:advmobdev_ta/models/task_model.dart';
import 'package:flutter/material.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Checkbox(value: task.completed, onChanged: (_) => onToggle()),
      title: Text(
        task.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(task.details),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
