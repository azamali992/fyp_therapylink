import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/user_role.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum AuthErrorType {
  invalidCredentials,
  userDisabled,
  tooManyAttempts,
  operationNotAllowed,
  emailAlreadyInUse,
  weakPassword,
  userNotFound,
  unknownError,
}

class AuthException implements Exception {
  final AuthErrorType errorType;
  final String message;

  AuthException(this.errorType, this.message);

  @override
  String toString() => message;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign up using email and password
  static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw AuthException(AuthErrorType.unknownError, 'Unknown error occurred');
    }
  }

  /// Sign in using email and password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw AuthException(AuthErrorType.unknownError, 'Unknown error occurred');
    }
  }

  /// Sign in with Google
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '975276530329-5u9pf583f3jun8orsrhgvm1op18hvh31.apps.googleusercontent.com' // ✅ Your Web OAuth Client ID
            : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('🚫 Google Sign-In was cancelled by the user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      final uid = user?.uid;

      print('✅ Google Sign-In successful.');
      print('📧 Email: ${user?.email}');
      print('🆔 UID: $uid');

      if (uid != null) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          print('🆕 New user detected. Assigning RegularUser role.');
          await saveUserRole(uid, UserRole.RegularUser);
        } else {
          print('🔄 Existing user found in Firestore.');
        }
      }

      return user;
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      return null;
    }
  }

  /// Save only user role (without extra profile fields)
  static Future<void> saveUserRole(String uid, UserRole role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'role': role.toString(),
    }, SetOptions(merge: true));
  }

  /// Save full user profile
  static Future<void> saveUserProfile(
    String uid,
    UserRole role, {
    required String age,
    required String dob,
    required String gender,
    required String phone,
    required String username,
    // required String profilePicUrl,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'role': role.toString(),
      'age': age,
      'dob': dob,
      'gender': gender,
      'phone': phone,
      'username': username,
      // 'profilePicUrl': profilePicUrl,
    }, SetOptions(merge: true));
  }

  /// Get user role from Firestore
  static Future<UserRole?> getUserRole(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final roleString = doc.data()?['role'] ?? '';

      if (roleString.contains('Professional')) {
        return UserRole.MentalHealthProfessional;
      } else if (roleString.contains('RegularUser')) {
        return UserRole.RegularUser;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user role: $e');
      return null;
    }
  }

  /// Sign out (including Google)
  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut(); // For Google sign-in
    } catch (_) {
      print('⚠️ Google sign-out skipped (maybe not signed in).');
    }
    await _auth.signOut();
    print('👋 User signed out.');
  }

  /// Get current Firebase user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Listen to auth state changes
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Handle FirebaseAuth errors
  static AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException(
            AuthErrorType.userNotFound, 'No user found for that email.');
      case 'wrong-password':
        return AuthException(
            AuthErrorType.invalidCredentials, 'Incorrect password.');
      case 'email-already-in-use':
        return AuthException(
            AuthErrorType.emailAlreadyInUse, 'Email is already in use.');
      case 'weak-password':
        return AuthException(
            AuthErrorType.weakPassword, 'Password is too weak.');
      case 'user-disabled':
        return AuthException(
            AuthErrorType.userDisabled, 'This user has been disabled.');
      case 'too-many-requests':
        return AuthException(AuthErrorType.tooManyAttempts,
            'Too many attempts. Try again later.');
      case 'operation-not-allowed':
        return AuthException(
            AuthErrorType.operationNotAllowed, 'Email sign-in is not enabled.');
      default:
        return AuthException(
            AuthErrorType.unknownError, 'Authentication error: ${e.message}');
    }
  }
}
