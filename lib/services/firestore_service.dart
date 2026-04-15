import 'package:advmobdev_ta/models/app_user.dart';
import 'package:advmobdev_ta/models/task_model.dart';
import 'package:advmobdev_ta/services/local_db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final bool _isWeb = kIsWeb;
  final FirebaseFirestore? _firestore = kIsWeb ? null : FirebaseFirestore.instance;

  String _collectionUserId(AppUser user) {
    if (_isWeb) {
      return user.uid;
    }
    final sessionUid = FirebaseAuth.instance.currentUser?.uid;
    if (sessionUid != null) {
      return sessionUid;
    }
    return user.uid;
  }

  Future<void> syncUserTasks(AppUser user, LocalDbService localDb) async {
    if (_isWeb) {
      debugPrint('Web fallback: skip Firestore sync');
      return;
    }

    debugPrint('Syncing tasks for user: ${user.uid}');
    final pending = await localDb.unsyncedTasks();
    for (final task in pending) {
      await _pushTaskToCloud(user, localDb, task);
    }
  }

  Future<void> syncSingleTask(
    AppUser user,
    TaskModel task,
    LocalDbService localDb,
  ) async {
    if (_isWeb || task.synced || task.id == null) {
      return;
    }
    await _pushTaskToCloud(user, localDb, task);
  }

  Future<void> _pushTaskToCloud(
    AppUser user,
    LocalDbService localDb,
    TaskModel task,
  ) async {
    if (_isWeb || task.id == null) {
      return;
    }

    if (task.deleted) {
      if (task.remoteId != null) {
        if (FirebaseAuth.instance.currentUser == null) {
          throw StateError(
            'You must be signed in with Firebase to sync task deletes.',
          );
        }
        try {
          await deleteTask(user, task.remoteId!);
        } catch (_) {
          // Document may already be removed.
        }
      }
      await localDb.deleteTaskPermanently(task.id!);
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError(
        'You must be signed in with Firebase to sync tasks to the cloud.',
      );
    }

    final docId = task.remoteId ?? task.id!.toString();
    await _firestore!
        .collection('users')
        .doc(_collectionUserId(user))
        .collection('tasks')
        .doc(docId)
        .set(task.toFirestoreMap(), SetOptions(merge: true));

    await localDb.updateTask(
      task.copyWith(
        remoteId: task.remoteId ?? docId,
        synced: true,
      ),
    );
  }

  Future<void> addTask(AppUser user, TaskModel task) async {
    if (_isWeb) {
      debugPrint('Web fallback: skip Firestore addTask');
      return;
    }

    await _firestore!
        .collection('users')
        .doc(_collectionUserId(user))
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
        .doc(_collectionUserId(user))
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
        .doc(_collectionUserId(user))
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
        .doc(_collectionUserId(user))
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }
}
