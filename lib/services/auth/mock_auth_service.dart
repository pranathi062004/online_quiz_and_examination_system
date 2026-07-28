import 'dart:async';
import '../../models/user_model.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  // Simple in-memory user database
  final Map<String, _MockUserCredentials> _userDb = {
    'admin@test.com': _MockUserCredentials(
      email: 'admin@test.com',
      password: 'admin123',
      user: UserModel(
        uid: 'admin_uid',
        email: 'admin@test.com',
        displayName: 'Admin Instructor',
        role: 'admin',
        createdAt: DateTime.now(),
      ),
    ),
    'student@test.com': _MockUserCredentials(
      email: 'student@test.com',
      password: 'student123',
      user: UserModel(
        uid: 'student_uid',
        email: 'student@test.com',
        displayName: 'John Doe',
        role: 'student',
        createdAt: DateTime.now(),
      ),
    ),
  };

  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  MockAuthService() {
    // Start session as logged out
    _authStateController.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network latency
    return _currentUser;
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    
    final credentials = _userDb[email.trim().toLowerCase()];
    if (credentials == null || credentials.password != password) {
      throw Exception('Invalid email or password');
    }

    _currentUser = credentials.user;
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    
    final formattedEmail = email.trim().toLowerCase();
    if (_userDb.containsKey(formattedEmail)) {
      throw Exception('Email already in use');
    }

    final newUser = UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: formattedEmail,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
    );

    _userDb[formattedEmail] = _MockUserCredentials(
      email: formattedEmail,
      password: password,
      user: newUser,
    );

    _currentUser = newUser;
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }
}

class _MockUserCredentials {
  final String email;
  final String password;
  final UserModel user;

  _MockUserCredentials({
    required this.email,
    required this.password,
    required this.user,
  });
}
