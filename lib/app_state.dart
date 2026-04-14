import 'dart:async';

import 'package:advmobdev_ta/models/app_user.dart';
import 'package:advmobdev_ta/models/task_model.dart';
import 'package:advmobdev_ta/services/auth_service.dart';
import 'package:advmobdev_ta/services/firestore_service.dart';
import 'package:advmobdev_ta/services/local_db_service.dart';
import 'package:advmobdev_ta/services/rest_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
      await loadTasks();
      if (online && authService.isUsingCloudAuth) {
        await syncTasks();
        await loadWeather();
      }
      await setStatus('Signed in successfully.');
    } catch (error) {
      await setStatus('Sign in failed: ${error.toString()}');
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
      await loadTasks();
      if (online && authService.isUsingCloudAuth) {
        await syncTasks();
        await loadWeather();
      }
      await setStatus('Account created successfully.');
    } catch (error) {
      await setStatus('Registration failed: ${error.toString()}');
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
    if (online && user != null) {
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
    if (online && user != null) {
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
    if (online && user != null) {
      await syncTasks();
    }
  }

  Future<void> syncTasks() async {
    if (user == null || !authService.isUsingCloudAuth) {
      return;
    }

    try {
      loading = true;
      notifyListeners();
      await firestoreService.syncUserTasks(user!);
      await loadTasks();
      await setStatus('Tasks synchronized with Firestore.');
    } catch (error) {
      await setStatus('Sync failed: ${error.toString()}');
    } finally {
      loading = false;
      notifyListeners();
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
