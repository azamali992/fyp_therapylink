import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'utils/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _loggedInKey = 'isLoggedIn';
  static const String _userRoleKey = 'userRole';

  /// Sign in with Google and set login state
  static Future<User?> signInWithGoogle({UserRole role = UserRole.RegularUser}) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Store login state locally
        await setLoggedIn(true, role);
      }

      return user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Sign out from Google and clear local storage
  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Google SignOut Error: $e');
    }

    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userRoleKey);
  }

  /// Store login status and role locally
  static Future<void> setLoggedIn(bool isLoggedIn, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, isLoggedIn);
    await prefs.setString(_userRoleKey, role.name); // save role as string (e.g. 'Admin')
  }

  /// Check if the user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  /// Get saved user role
  static Future<UserRole?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final String? roleString = prefs.getString(_userRoleKey);

    if (roleString != null) {
      try {
        return UserRole.values.firstWhere((e) => e.name == roleString);
      } catch (e) {
        print('Invalid user role in SharedPreferences');
      }
    }

    return null;
  }

  /// Get the current Firebase user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
