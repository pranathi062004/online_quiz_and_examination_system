import '../../models/user_model.dart';

abstract class AuthService {
  Future<UserModel?> signInWithEmailAndPassword(String email, String password);
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String role,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<void> sendPasswordResetEmail(String email);
}
