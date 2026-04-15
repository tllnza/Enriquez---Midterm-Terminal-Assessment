import 'package:advmobdev_ta/app_state.dart';
import 'package:advmobdev_ta/widgets/network_banner.dart';
import 'package:advmobdev_ta/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final topPad = MediaQuery.paddingOf(context).top;

    if (state.statusMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.statusMessage!),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
          state.clearStatus();
        }
      });
    }

    final syncedCount = state.tasks.where((t) => t.synced).length;
    final pendingCount = state.tasks.length - syncedCount;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Field Agent Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: state.user != null && state.authService.isUsingCloudAuth
                ? state.syncTasks
                : null,
            tooltip: 'Sync all pending tasks',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: state.signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: RefreshIndicator(
        edgeOffset: topPad + kToolbarHeight + 24,
        onRefresh: () async {
          await state.loadTasks();
          if (state.online) {
            await state.syncTasks();
            await state.loadWeather();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroHeader(theme: theme),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  NetworkBanner(online: state.online),
                  const SizedBox(height: 16),
                  _buildWeatherCard(context, state),
                  const SizedBox(height: 20),
                  _buildTaskSectionHeader(
                    context,
                    state,
                    syncedCount,
                    pendingCount,
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            if (state.tasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 72,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add a draft. It stays on your device until you sync to the cloud.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  itemCount: state.tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = state.tasks[index];
                    return TaskTile(
                      task: task,
                      online: state.online,
                      cloudSyncEnabled: state.authService.isUsingCloudAuth,
                      onToggle: () => state.toggleTask(task),
                      onDelete: () => state.removeTask(task),
                      onSync: () => state.syncSingleTask(task),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
    );
  }

  Widget _buildTaskSectionHeader(
    BuildContext context,
    AppState state,
    int syncedCount,
    int pendingCount,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your tasks',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SQLite drafts • Tap Sync when you are online',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              icon: Icons.cloud_done_rounded,
              label: 'Synced',
              count: syncedCount,
              color: theme.colorScheme.secondaryContainer,
              onColor: theme.colorScheme.onSecondaryContainer,
            ),
            _SummaryChip(
              icon: Icons.cloud_upload_rounded,
              label: 'Pending',
              count: pendingCount,
              color: theme.colorScheme.tertiaryContainer,
              onColor: theme.colorScheme.onTertiaryContainer,
            ),
            _SummaryChip(
              icon: Icons.list_alt_rounded,
              label: 'Total',
              count: state.tasks.length,
              color: theme.colorScheme.surfaceContainerHighest,
              onColor: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherCard(BuildContext context, AppState state) {
    final theme = Theme.of(context);

    if (!state.online) {
      return _WeatherShell(
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You are offline. Weather will appear when you reconnect.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (state.weather == null) {
      return _WeatherShell(
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text('Loading weather…', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    final w = state.weather!;
    return _WeatherShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.wb_cloudy_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live weather',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  w.summary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  w.details,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskSheet(BuildContext context) async {
    final state = context.read<AppState>();
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 28,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New draft task',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved locally first. Sync when you are online.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Details are required'
                      : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      await state.addTask(
                        titleController.text,
                        detailsController.text,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save to device'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final ThemeData theme;

  const _HeroHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.paddingOf(context).top + kToolbarHeight + 28;
    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
            theme.colorScheme.tertiary.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                Icon(
                  Icons.shield_moon_rounded,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stay organized in the field',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherShell extends StatelessWidget {
  final Widget child;

  const _WeatherShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(18),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: child,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color onColor;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: onColor),
      label: Text('$label · $count'),
      backgroundColor: color,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: onColor,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
