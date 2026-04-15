import 'dart:async';

import 'package:advmobdev_ta/models/app_user.dart';
import 'package:advmobdev_ta/models/task_model.dart';
import 'package:advmobdev_ta/services/auth_service.dart';
import 'package:advmobdev_ta/services/firestore_service.dart';
import 'package:advmobdev_ta/services/local_db_service.dart';
import 'package:advmobdev_ta/services/rest_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  final AuthService authService = AuthService();
  final LocalDbService localDb = LocalDbService.instance;
  final FirestoreService firestoreService = FirestoreService();
  final RestService restService = RestService();

  bool loading = true;
  bool online = false;
  String? statusMessage;
  AppUser? user;
  List<TaskModel> tasks = [];
  WeatherData? weather;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<AppUser?>? _userSubscription;

  AppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    await authService.ensureInitialized();

    user = authService.currentUser;
    _userSubscription = authService.userChanges.listen((updatedUser) {
      user = updatedUser;
      if (user != null) {
        syncTasks();
      } else {
        tasks = [];
      }
      notifyListeners();
    });

    final connectivity = Connectivity();
    online = await _checkConnection(connectivity);
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      online = result != ConnectivityResult.none;
      if (online) {
        await syncTasks();
        await loadWeather();
      }
      notifyListeners();
    });

    await loadTasks();
    if (user != null && online) {
      await syncTasks();
    }
    if (online) {
      await loadWeather();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> _checkConnection(Connectivity connectivity) async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> setStatus(String message) async {
    statusMessage = message;
    notifyListeners();
  }

  void clearStatus() {
    statusMessage = null;
  }

  Future<void> signIn(String email, String password) async {
    try {
      loading = true;
      notifyListeners();
      await authService.signIn(email, password);
      user = authService.currentUser;
      notifyListeners();
      await loadTasks();
      if (authService.isUsingCloudAuth && authService.hasFirebaseSession) {
        await syncTasks();
      }
      if (online) {
        await loadWeather();
      }
      await setStatus('Signed in successfully.');
    } catch (error) {
      await setStatus(_messageForAuthFailure('Sign in failed', error));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    try {
      loading = true;
      notifyListeners();
      await authService.register(email, password);
      user = authService.currentUser;
      notifyListeners();
      await loadTasks();
      if (authService.isUsingCloudAuth && authService.hasFirebaseSession) {
        await syncTasks();
      }
      if (online) {
        await loadWeather();
      }
      await setStatus('Account created successfully.');
    } catch (error) {
      await setStatus(_messageForAuthFailure('Registration failed', error));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await authService.signOut();
    user = null;
    tasks = [];
    await setStatus('Signed out successfully.');
    notifyListeners();
  }

  Future<void> loadTasks() async {
    tasks = await localDb.getTasks(activeOnly: true);
    notifyListeners();
  }

  Future<void> addTask(String title, String details) async {
    final newTask = TaskModel(
      title: title,
      details: details,
      completed: false,
      synced: false,
      deleted: false,
      updatedAt: DateTime.now(),
    );
    await localDb.insertTask(newTask);
    await loadTasks();
    if (user != null &&
        authService.isUsingCloudAuth &&
        authService.hasFirebaseSession) {
      await syncTasks();
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    final updatedTask = task.copyWith(
      completed: !task.completed,
      synced: false,
      updatedAt: DateTime.now(),
    );
    await localDb.updateTask(updatedTask);
    await loadTasks();
    if (user != null &&
        authService.isUsingCloudAuth &&
        authService.hasFirebaseSession) {
      await syncTasks();
    }
  }

  Future<void> removeTask(TaskModel task) async {
    final deletedTask = task.copyWith(
      deleted: true,
      synced: false,
      updatedAt: DateTime.now(),
    );
    await localDb.updateTask(deletedTask);
    await loadTasks();
    if (user != null &&
        authService.isUsingCloudAuth &&
        authService.hasFirebaseSession) {
      await syncTasks();
    }
  }

  Future<void> syncTasks() async {
    if (user == null) {
      await setStatus('Sign in to sync tasks.');
      return;
    }
    if (!authService.isUsingCloudAuth) {
      await setStatus(
        'Cloud sync needs Firebase login. Sign out and sign in with email and password.',
      );
      return;
    }
    if (!authService.hasFirebaseSession) {
      await setStatus(
        'No active Firebase session. Sign out and sign in again, then try Sync.',
      );
      return;
    }

    try {
      await firestoreService.syncUserTasks(user!, localDb);
      await loadTasks();
      await setStatus('Tasks synchronized with Firestore.');
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        await setStatus(
          'Firestore permission denied. In Firebase Console → Firestore → Rules, allow users/{userId}/tasks for signed-in users (userId must match auth.uid).',
        );
      } else if (_isFirestoreDatabaseMissing(error)) {
        await setStatus(_firestoreMissingMessage);
      } else {
        await setStatus('Sync failed: ${error.message ?? error.code}');
      }
    } catch (error) {
      if (_isFirestoreDatabaseMissingString(error.toString())) {
        await setStatus(_firestoreMissingMessage);
      } else {
        await setStatus('Sync failed: ${error.toString()}');
      }
    }
  }

  Future<void> syncSingleTask(TaskModel task) async {
    if (user == null) {
      await setStatus('Sign in to sync tasks.');
      return;
    }
    if (!authService.isUsingCloudAuth) {
      await setStatus(
        'Cloud sync needs Firebase login. Sign out and sign in with email and password.',
      );
      return;
    }
    if (!authService.hasFirebaseSession) {
      await setStatus(
        'No active Firebase session. Sign out and sign in again, then try Sync.',
      );
      return;
    }
    try {
      await firestoreService.syncSingleTask(user!, task, localDb);
      await loadTasks();
      await setStatus('Task synced to Firestore.');
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        await setStatus(
          'Firestore permission denied. Update Firestore security rules for users/{userId}/tasks.',
        );
      } else if (_isFirestoreDatabaseMissing(error)) {
        await setStatus(_firestoreMissingMessage);
      } else {
        await setStatus('Sync failed: ${error.message ?? error.code}');
      }
    } catch (error) {
      if (_isFirestoreDatabaseMissingString(error.toString())) {
        await setStatus(_firestoreMissingMessage);
      } else {
        await setStatus('Sync failed: ${error.toString()}');
      }
    }
  }

  Future<void> loadWeather() async {
    if (!online) {
      return;
    }

    try {
      weather = await restService.fetchWeather();
      notifyListeners();
    } catch (error) {
      await setStatus('Unable to fetch weather: ${error.toString()}');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}

const String _firestoreMissingMessage =
    'Firestore is not created yet. Firebase Console → Build → Firestore Database → Create database '
    '(start in test mode for development), pick a region, then try Sync again.';

bool _isFirestoreDatabaseMissing(FirebaseException error) {
  final c = error.code.toLowerCase();
  final m = (error.message ?? '').toLowerCase();
  return c == 'not-found' ||
      c == 'failed-precondition' ||
      m.contains('does not exist') ||
      m.contains('database (default) does not exist');
}

bool _isFirestoreDatabaseMissingString(String s) {
  final lower = s.toLowerCase();
  return lower.contains('not_found') ||
      lower.contains('not-found') ||
      lower.contains('does not exist') ||
      lower.contains('database (default) does not exist');
}

String _messageForAuthFailure(String prefix, Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('configuration_not_found') ||
      lower.contains('configuration-not-found') ||
      raw.contains('CONFIGURATION_NOT_FOUND')) {
    return '$prefix: Firebase Auth backend could not load your project config. '
        'In Google Cloud Console enable the Identity Toolkit API for this Firebase project. '
        'In Firebase Console enable Authentication → Email/Password, add your debug SHA-1 '
        'under Project settings → Your Android app, then download a fresh google-services.json '
        'and replace android/app/google-services.json (the oauth_client array should not be empty). '
        'Run flutter clean and rebuild.';
  }
  return '$prefix: $raw';
}
