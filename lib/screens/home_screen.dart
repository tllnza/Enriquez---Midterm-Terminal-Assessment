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

    if (state.statusMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.statusMessage!)));
          state.clearStatus();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Agent Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: state.online ? state.syncTasks : null,
            tooltip: 'Sync now',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: state.signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await state.loadTasks();
            if (state.online) {
              await state.syncTasks();
              await state.loadWeather();
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              NetworkBanner(online: state.online),
              const SizedBox(height: 16),
              _buildWeatherCard(state),
              const SizedBox(height: 16),
              _buildTaskHeader(state),
              const SizedBox(height: 12),
              if (state.tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'No local tasks yet. Use the + button to create local draft tasks and sync them later.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...state.tasks.map(
                  (task) => Column(
                    children: [
                      TaskTile(
                        task: task,
                        onToggle: () => state.toggleTask(task),
                        onDelete: () => state.removeTask(task),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeatherCard(AppState state) {
    if (!state.online) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'External resource',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Offline, external API data will load when you reconnect.'),
            ],
          ),
        ),
      );
    }

    if (state.weather == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'External resource',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(state.weather!.summary, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text(state.weather!.details),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Draft Tasks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '${state.tasks.length} items',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Draft Task',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: detailsController,
                  decoration: const InputDecoration(labelText: 'Details'),
                  minLines: 2,
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Details are required'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
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
                  child: const Text('Save Task'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
