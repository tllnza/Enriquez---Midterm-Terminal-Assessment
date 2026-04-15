import '../models/task_model.dart';

class LocalDbService {
  LocalDbService._();

  static final LocalDbService instance = LocalDbService._();

  final List<TaskModel> _tasks = [];
  int _nextId = 1;

  Future<void> init() async {
    return;
  }

  Future<List<TaskModel>> getTasks({bool activeOnly = true}) async {
    final result = _tasks.where((task) => !task.deleted).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<List<TaskModel>> unsyncedTasks() async {
    final result = _tasks.where((task) => !task.synced && !task.deleted).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<TaskModel?> getTaskByRemoteId(String remoteId) async {
    try {
      return _tasks.firstWhere((task) => task.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  Future<TaskModel> insertTask(TaskModel task) async {
    final added = task.copyWith(id: _nextId++, synced: false);
    _tasks.add(added);
    return added;
  }

  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    }
  }

  Future<void> deleteTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    }
  }

  Future<void> deleteTaskPermanently(int id) async {
    _tasks.removeWhere((t) => t.id == id);
  }
}
