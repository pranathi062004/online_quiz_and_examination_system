import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserFromFirestore(firebaseUser.uid, firebaseUser.email ?? '');
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return await _getUserFromFirestore(firebaseUser.uid, firebaseUser.email ?? '');
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      // 1. Verify if user account exists in Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .get()
          .timeout(const Duration(seconds: 4));

      if (userQuery.docs.isEmpty) {
        throw Exception('You do not have an account. Please register first.');
      }

      // 2. Perform authentication
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      ).timeout(const Duration(seconds: 8));
      
      if (credential.user == null) {
        throw Exception('User is null after successful login');
      }
      return await _getUserFromFirestore(credential.user!.uid, credential.user!.email ?? email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Incorrect password. Please try again.');
      }
      throw Exception(e.message ?? 'An unknown authentication error occurred');
    } on TimeoutException {
      throw Exception('Login timed out. Please check your network connection.');
    }
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(const Duration(seconds: 8));
      
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('User is null after successful registration');
      }

      // Update display name in Firebase Auth
      await firebaseUser.updateDisplayName(displayName).timeout(const Duration(seconds: 4));

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: email.trim().toLowerCase(),
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
      );

      // Save user profile details to Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap()).timeout(const Duration(seconds: 4));

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An unknown registration error occurred');
    } on TimeoutException {
      throw Exception('Registration timed out. Please check your network connection.');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim()).timeout(const Duration(seconds: 6));
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An error occurred during password reset');
    }
  }

  // Helper method to fetch user profile details from Firestore
  Future<UserModel> _getUserFromFirestore(String uid, String email) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get().timeout(
        const Duration(seconds: 6),
      );
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      // Log error internally, fallback to a basic user model
      debugPrint('Error fetching user from Firestore: $e');
    }

    // Default fallback user model
    return UserModel(
      uid: uid,
      email: email,
      displayName: email.split('@').first,
      role: 'student',
      createdAt: DateTime.now(),
    );
  }
}
