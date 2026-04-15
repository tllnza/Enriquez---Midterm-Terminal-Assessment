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
  final _userChangesController = StreamController<AppUser?>.broadcast();

  AuthService();

  Stream<AppUser?> get userChanges {
    if (_isWeb || !_firebaseAuthEnabled) {
      return _userChangesController.stream;
    }
    return _auth!.authStateChanges().map(_toAppUser);
  }

  /// Firestore + cloud features require a real Firebase session on mobile.
  bool get isUsingCloudAuth =>
      !_isWeb && _firebaseAuthEnabled && _auth != null && _auth.currentUser != null;

  bool get hasFirebaseSession {
    if (_isWeb || _auth == null) {
      return false;
    }
    return _auth.currentUser != null;
  }

  AppUser? get currentUser {
    if (_isWeb || !_firebaseAuthEnabled) {
      return _currentUser;
    }
    if (_auth == null) {
      return null;
    }
    return _toAppUser(_auth.currentUser);
  }

  Future<void> ensureInitialized() async {
    return;
  }

  Future<void> signIn(String email, String password) async {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (_isWeb || !_firebaseAuthEnabled) {
      final user = AppUser(uid: 'local_user_${email.hashCode}', email: email);
      _currentUser = user;
      _userChangesController.add(user);
      return;
    }

    await _auth!.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> register(String email, String password) async {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (_isWeb || !_firebaseAuthEnabled) {
      final user = AppUser(uid: 'local_user_${email.hashCode}', email: email);
      _currentUser = user;
      _userChangesController.add(user);
      return;
    }

    await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (_isWeb || !_firebaseAuthEnabled) {
      _currentUser = null;
      _userChangesController.add(null);
      return;
    }

    await _auth!.signOut();
  }

  AppUser? _toAppUser(fb.User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
  }
}
