import 'package:shared_preferences/shared_preferences.dart';
import 'utils/user_role.dart';

class AuthService {
  static const String _loggedInKey = 'isLoggedIn';
  static const String _userRoleKey = 'userRole';

  static Future<void> setLoggedIn(bool isLoggedIn, UserRole role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, isLoggedIn);
    await prefs.setString(_userRoleKey, role.toString());
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<UserRole?> getUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? roleString = prefs.getString(_userRoleKey);
    if (roleString != null) {
      return UserRole.values
          .firstWhere((role) => role.toString() == roleString);
    }
    return null;
  }

  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userRoleKey);
  }
}
