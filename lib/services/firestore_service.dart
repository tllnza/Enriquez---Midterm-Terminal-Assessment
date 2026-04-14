import 'package:advmobdev_ta/models/app_user.dart';
import 'package:advmobdev_ta/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final bool _isWeb = kIsWeb;
  final FirebaseFirestore? _firestore = kIsWeb ? null : FirebaseFirestore.instance;

  Future<void> syncUserTasks(AppUser user) async {
    if (_isWeb) {
      debugPrint('Web fallback: skip Firestore sync');
      return;
    }

    try {
      debugPrint('Syncing tasks for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error syncing tasks: $e');
    }
  }

  Future<void> addTask(AppUser user, TaskModel task) async {
    if (_isWeb) {
      debugPrint('Web fallback: skip Firestore addTask');
      return;
    }

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(task.remoteId ?? task.id.toString())
        .set(task.toFirestoreMap());
  }

  Future<void> updateTask(AppUser user, TaskModel task) async {
    if (_isWeb) {
      debugPrint('Web fallback: skip Firestore updateTask');
      return;
    }

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(task.remoteId ?? task.id.toString())
        .update(task.toFirestoreMap());
  }

  Future<void> deleteTask(AppUser user, String taskId) async {
    if (_isWeb) {
      debugPrint('Web fallback: skip Firestore deleteTask');
      return;
    }

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Stream<List<TaskModel>> getUserTasks(AppUser user) {
    if (_isWeb) {
      return Stream.value(<TaskModel>[]);
    }

    return _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }
}
