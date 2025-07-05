import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppConstants {
  // Padding and Margins
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // Border Radius
  static const double borderRadius = 10.0;
  static const double smallBorderRadius = 5.0;
  static const double largeBorderRadius = 25.0;
  static const double extraLargeBorderRadius = 50.0;

  // Font Sizes
  static const double smallFontSize = 14.0;
  static const double mediumFontSize = 16.0;
  static const double largeFontSize = 24.0;
  static const double extraLargeFontSize = 40.0;
  static const double titleFontSize = 32.0;
  static const double subtitleFontSize = 18.0;

  // Button Sizes
  static const double buttonHeight = 50.0;
  static const double buttonWidth = 200.0;
  static const double smallButtonHeight = 40.0;
  static const double largeButtonHeight = 60.0;

  // Icon Sizes
  static const double smallIconSize = 20.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 40.0;
  static const double extraLargeIconSize = 60.0;

  // Divider
  static const double dividerThickness = 1.0;
  static const double largeDividerThickness = 2.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Elevations
  static const double cardElevation = 4.0;
  static const double buttonElevation = 2.0;

  // Spacing
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 16.0;
  static const double extraLargeSpacing = 24.0;

  // Avatar
  static const double avatarRadius = 30.0;
  static const double smallAvatarRadius = 20.0;
  static const double largeAvatarRadius = 50.0;

  // Text Field Heights
  static const double textFieldHeight = 50.0;

  // Shadows
  static const double shadowBlurRadius = 10.0;
  static const double shadowSpreadRadius = 2.0;

  // Authentication (User Storage)
  static Map<String, String> users = {};

  // Load Users from SharedPreferences
  static Future<void> loadUsers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUsers = prefs.getString("users");

    if (storedUsers != null) {
      users = Map<String, String>.from(json.decode(storedUsers));
    }
  }

  // Save Users to SharedPreferences
  static Future<void> saveUsers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("users", json.encode(users));
  }

  // Function to Add a New User
  static Future<bool> addUser(String email, String password) async {
    if (!users.containsKey(email)) {
      users[email] = password;
      await saveUsers(); // Save the updated user list
      return true;
    }
    return false;
  }

  // Function to Validate Login
  static bool validateUser(String email, String password) {
    return users.containsKey(email) && users[email] == password;
  }
}
// constants.dart

