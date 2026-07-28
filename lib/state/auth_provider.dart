import 'dart:async';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../models/user_model.dart';
import '../services/service_locator.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserModel?>? _authSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _authSubscription?.cancel();

    _user = await locator.authService.getCurrentUser();
    _isLoading = false;
    notifyListeners();

    // Listen for auth state changes
    _authSubscription = locator.authService.authStateChanges.listen((userModel) {
      _user = userModel;
      notifyListeners();
    });
  }

  Future<void> toggleMockMode(bool enable, {String? defaultEmail}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    AppConfig.useMock = enable;
    locator.setup();
    await _init();

    if (enable && defaultEmail != null) {
      // Auto login in mock mode with matching role
      final lowerEmail = defaultEmail.toLowerCase();
      if (lowerEmail.contains('admin')) {
        await login('admin@test.com', 'admin123');
      } else {
        await login('student@test.com', 'student123');
      }
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await locator.authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await locator.authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
      // Immediately sign out to prevent auto-login
      await locator.authService.signOut();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await locator.authService.signOut();
    _user = null;
    _isLoading = false;
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await locator.authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
