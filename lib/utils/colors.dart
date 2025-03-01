import 'package:flutter/material.dart';

class AppColors {
  // Background Colors
  static const Color backgroundGradientStart = Color(0xFF1d1e2c);
  static const Color backgroundGradientEnd = Color.fromARGB(255, 52, 6, 63);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);

  static const Color bgpurple = Color.fromARGB(255, 52, 6, 63);
  static const Color bgpink = Color(0xFFF23598);

  static const Color bgdarkgreen = Color(0xFF38A711);
  static const Color bgreen = Color(0xFF89F336);

  // Social Media Colors
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color googleRed = Color(0xFFDB4437);
  static const Color appleBlack = Colors.black;

  // Semi-Transparent Colors
  static const Color semiTransparentWhite = Color(0x33FFFFFF); // 20% opacity
  static const Color semiTransparentBlack = Color(0x33000000); // 20% opacity

  // Divider Colors
  static const Color dividerColor = Colors.white;

  // Text Colors
  static const Color textWhite = Colors.white;
  static const Color textGray = Colors.grey;
  static const Color textBlack = Colors.black;
  static const Color textDarkGrey = Color(0xFF414040);
  static const Color textDarkBlue = Color(0xFF001F54); // Navy Blue

  // Button Gradient Colors
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF001F54), // Dark Blue
      Color(0xFF0077B6), // Light Blue
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Error Colors
  static const Color errorRed = Color(0xFFFF4C4C);

  // Success Colors
  static const Color successGreen = Color(0xFF4CAF50);

  // Icon Colors
  static const Color iconDarkGrey = Color(0xFF616161);
  static const Color iconLightGrey = Color(0xFFBDBDBD);
}
