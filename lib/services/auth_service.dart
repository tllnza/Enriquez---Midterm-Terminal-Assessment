import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:advmobdev_ta/models/app_user.dart';

class AuthService {
  static const bool _firebaseAuthEnabled = bool.fromEnvironment(
    'USE_FIREBASE_AUTH',
    defaultValue: true,
  );
  final bool _isWeb = kIsWeb;
  final fb.FirebaseAuth? _auth = kIsWeb ? null : fb.FirebaseAuth.instance;
  AppUser? _currentUser;
  bool _useLocalAuthFallback = !_firebaseAuthEnabled;
  final _userChangesController = StreamController<AppUser?>.broadcast();

  AuthService() {
    if (!_isWeb && !_useLocalAuthFallback) {
      _auth!.authStateChanges().listen((firebaseUser) {
        final user = _toAppUser(firebaseUser);
        _currentUser = user;
        _userChangesController.add(user);
      });
    }
  }

  Stream<AppUser?> get userChanges => _isWeb
      ? _userChangesController.stream
      : (_useLocalAuthFallback
            ? _userChangesController.stream
            : _auth!.authStateChanges().map(_toAppUser));

  bool get isUsingCloudAuth => !_isWeb && !_useLocalAuthFallback;

  AppUser? get currentUser {
    if (_isWeb || _useLocalAuthFallback) {
      return _currentUser;
    }
    return _toAppUser(_auth!.currentUser);
  }

  Future<void> ensureInitialized() async {
    return;
  }

  Future<void> signIn(String email, String password) async {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (_isWeb || _useLocalAuthFallback) {
      final user = AppUser(uid: 'local_user_${email.hashCode}', email: email);
      _currentUser = user;
      _userChangesController.add(user);
      return;
    }

    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _toAppUser(credential.user);
      _currentUser = user;
      _userChangesController.add(user);
    } on fb.FirebaseAuthException catch (error) {
      if (_isFirebaseConfigError(error)) {
        _activateLocalFallback(email);
        return;
      }
      rethrow;
    } catch (error) {
      if (_isFirebaseConfigErrorFromMessage(error.toString())) {
        _activateLocalFallback(email);
        return;
      }
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (_isWeb || _useLocalAuthFallback) {
      final user = AppUser(uid: 'local_user_${email.hashCode}', email: email);
      _currentUser = user;
      _userChangesController.add(user);
      return;
    }

    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _toAppUser(credential.user);
      _currentUser = user;
      _userChangesController.add(user);
    } on fb.FirebaseAuthException catch (error) {
      if (_isFirebaseConfigError(error)) {
        _activateLocalFallback(email);
        return;
      }
      rethrow;
    } catch (error) {
      if (_isFirebaseConfigErrorFromMessage(error.toString())) {
        _activateLocalFallback(email);
        return;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_isWeb || _useLocalAuthFallback) {
      _currentUser = null;
      _userChangesController.add(null);
      return;
    }

    await _auth!.signOut();
  }

  AppUser? _toAppUser(fb.User? firebaseUser) {
    if (firebaseUser == null) return null;
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
  }

  bool _isFirebaseConfigError(fb.FirebaseAuthException error) {
    final message = error.message?.toLowerCase() ?? '';
    return error.code == 'invalid-api-key' ||
        error.code == 'unknown' ||
        error.code == 'internal-error' ||
        message.contains('api key not valid') ||
        message.contains('configuration-not-found');
  }

  bool _isFirebaseConfigErrorFromMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('api key not valid') ||
        normalized.contains('invalid-api-key') ||
        normalized.contains('configuration-not-found');
  }

  void _activateLocalFallback(String email) {
    _useLocalAuthFallback = true;
    final user = AppUser(uid: 'local_user_${email.hashCode}', email: email);
    _currentUser = user;
    _userChangesController.add(user);
  }
}
