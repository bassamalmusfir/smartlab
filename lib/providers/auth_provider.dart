import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<User?>? _authSubscription;

  UserModel? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  // False until Firebase has told us whether a saved login exists.
  bool get initialized => _initialized;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    try {
      _authSubscription = _firebaseService.authStateChanges().listen(_onAuthChanged);
    } catch (e) {
      debugPrint('Auth state unavailable: $e');
      _initialized = true;
    }
  }

  // Restores the saved login on app start.
  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isAdmin = false;
    } else if (_currentUser?.id != firebaseUser.uid) {
      try {
        // Null during sign-up, before the profile is written; signup() sets it.
        final profile = await _firebaseService.getUserData(firebaseUser.uid);
        if (profile != null) {
          _currentUser = profile;
          await _loadAdminStatus();
        }
      } catch (e) {
        debugPrint('Could not restore login: $e');
      }
    }
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  static String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _loadAdminStatus() async {
    final user = _currentUser;
    _isAdmin = user != null && await _firebaseService.isAdmin(user.id);
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = _message(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup({
    required String email,
    required String username,
    required String password,
    required int age,
  }) {
    return _run(() async {
      _currentUser = await _firebaseService.signUp(
        email: email,
        username: username,
        password: password,
        age: age,
      );
      _isAdmin = false;
    });
  }

  Future<bool> login({required String email, required String password}) {
    return _run(() async {
      _currentUser = await _firebaseService.login(email: email, password: password);
      await _loadAdminStatus();
    });
  }

  Future<void> logout() async {
    await _run(() async {
      await _firebaseService.logout();
      _currentUser = null;
      _isAdmin = false;
    });
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _firebaseService.sendPasswordReset(email));
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) {
    return _run(() => _firebaseService.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ));
  }

  Future<bool> deleteAccount(String password) {
    return _run(() async {
      await _firebaseService.deleteAccount(password);
      _currentUser = null;
      _isAdmin = false;
    });
  }

  Future<bool> updateUserData(UserModel user) {
    return _run(() async {
      await _firebaseService.updateUserData(user);
      _currentUser = user;
    });
  }

  // Counts one analysis against the user's limit.
  Future<void> recordAnalysisUsed() async {
    final user = _currentUser;
    if (user == null) return;
    await _firebaseService.recordAnalysisUsed(user.id);
    _currentUser = user.copyWith(analysesUsed: user.analysesUsed + 1);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
