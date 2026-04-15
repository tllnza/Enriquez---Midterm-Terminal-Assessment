import 'package:advmobdev_ta/models/task_model.dart';
import 'package:flutter/material.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final bool online;
  final bool cloudSyncEnabled;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSync;

  const TaskTile({
    super.key,
    required this.task,
    required this.online,
    required this.cloudSyncEnabled,
    required this.onToggle,
    required this.onDelete,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPushSync =
        cloudSyncEnabled && !task.synced && !task.deleted;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: task.completed
                          ? theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.6)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      task.completed
                          ? Icons.check_rounded
                          : Icons.assignment_outlined,
                      color: task.completed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.completed
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SyncStatusChip(
                    synced: task.synced,
                    online: online,
                    cloudSyncEnabled: cloudSyncEnabled,
                  ),
                  const Spacer(),
                  if (canPushSync)
                    FilledButton.tonalIcon(
                      onPressed: onSync,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Sync'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Remove task',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  final bool synced;
  final bool online;
  final bool cloudSyncEnabled;

  const _SyncStatusChip({
    required this.synced,
    required this.online,
    required this.cloudSyncEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (synced) {
      return Chip(
        avatar: Icon(
          Icons.cloud_done_rounded,
          size: 18,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        label: const Text('Synced to cloud'),
        side: BorderSide.none,
        backgroundColor: theme.colorScheme.secondaryContainer,
        visualDensity: VisualDensity.compact,
      );
    }

    if (!cloudSyncEnabled) {
      return Chip(
        avatar: Icon(
          Icons.smartphone_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        label: const Text('Local only'),
        side: BorderSide.none,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      );
    }

    if (!online) {
      return Chip(
        avatar: Icon(
          Icons.cloud_upload_outlined,
          size: 18,
          color: theme.colorScheme.onTertiaryContainer,
        ),
        label: const Text('Tap Sync to upload'),
        side: BorderSide.none,
        backgroundColor: theme.colorScheme.tertiaryContainer.withValues(
          alpha: 0.65,
        ),
        visualDensity: VisualDensity.compact,
      );
    }

    return Chip(
      avatar: Icon(
        Icons.cloud_queue_rounded,
        size: 18,
        color: theme.colorScheme.onTertiaryContainer,
      ),
      label: const Text('Ready to sync'),
      side: BorderSide.none,
      backgroundColor: theme.colorScheme.tertiaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}
