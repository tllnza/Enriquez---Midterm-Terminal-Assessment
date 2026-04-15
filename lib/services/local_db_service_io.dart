import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task_model.dart';

class LocalDbService {
  LocalDbService._();

  static final LocalDbService instance = LocalDbService._();

  Database? _database;

  Future<void> init() async {
    if (_database != null) {
      return;
    }

    final docsDirectory = await getApplicationDocumentsDirectory();
    final path = join(docsDirectory.path, 'field_agent_tasks.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remoteId TEXT,
            title TEXT NOT NULL,
            details TEXT NOT NULL,
            completed INTEGER NOT NULL,
            synced INTEGER NOT NULL,
            deleted INTEGER NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<TaskModel>> getTasks({bool activeOnly = true}) async {
    await init();
    final whereClause = activeOnly ? 'WHERE deleted = 0' : '';
    final rows = await _database!.rawQuery(
      'SELECT * FROM tasks $whereClause ORDER BY updatedAt DESC',
    );
    return rows.map((row) => TaskModel.fromMap(row)).toList();
  }

  Future<List<TaskModel>> unsyncedTasks() async {
    await init();
    final rows = await _database!.query(
      'tasks',
      where: 'synced = 0',
      orderBy: 'updatedAt DESC',
    );
    return rows.map((row) => TaskModel.fromMap(row)).toList();
  }

  Future<TaskModel?> getTaskByRemoteId(String remoteId) async {
    await init();
    final rows = await _database!.query(
      'tasks',
      where: 'remoteId = ?',
      whereArgs: [remoteId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return TaskModel.fromMap(rows.first);
  }

  Future<TaskModel> insertTask(TaskModel task) async {
    await init();
    final id = await _database!.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<void> updateTask(TaskModel task) async {
    await init();
    final map = task.toMap();
    await _database!.update(
      'tasks',
      map,
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(TaskModel task) async {
    await init();

    if (task.remoteId == null) {
      await _database!.delete('tasks', where: 'id = ?', whereArgs: [task.id]);
      return;
    }

    await _database!.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTaskPermanently(int id) async {
    await init();
    await _database!.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
