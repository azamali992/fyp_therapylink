import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapylink/Views/bottomnav.dart';
import 'package:therapylink/Views/signup.dart';
import 'dart:convert';
import '../utils/colors.dart';
import '../utils/strings.dart';
import '../utils/constants.dart';
import 'package:therapylink/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Function to validate login from stored users
  Future<bool> validateUser(String email, String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUsers = prefs.getString("users");

    if (storedUsers != null) {
      Map<String, String> users =
          Map<String, String>.from(json.decode(storedUsers));
      return users.containsKey(email) && users[email] == password;
    }
    return false;
  }

  void _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    bool isValid = await validateUser(email, password);

    if (isValid) {
      await AuthService.setLoggedIn(true); // Add this line
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleBottomBar()),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Invalid username or password";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.04,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenHeight * 0.06), // Restored from 0.02

                  // Logo
                  Center(
                    child: SizedBox(
                      width: screenWidth * 0.7,
                      height: screenHeight * 0.15, // Restored from 0.12
                      child: Image.asset(
                        'assets/therapylink_logofull.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04), // Restored from 0.02

                  // Welcome Text
                  const Text(
                    AppStrings.loginToTherapyLink,
                    style: TextStyle(
                      fontSize: AppConstants.largeFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  const Text(
                    AppStrings.welcomeMessage,
                    style: TextStyle(
                      fontSize: AppConstants.mediumFontSize,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.06), // Restored from 0.03

                  // Login Form Container with Glassmorphism
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.largeBorderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(
                            screenWidth * 0.06), // Restored from 0.04
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                              AppConstants.largeBorderRadius),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            // Email TextField
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppStrings.emailPlaceholder,
                                labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.8)),
                                prefixIcon: const Icon(Icons.email,
                                    color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            // Password TextField
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppStrings.passwordPlaceholder,
                                labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.8)),
                                prefixIcon: const Icon(Icons.lock,
                                    color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.02),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.04),

                  // Login Button
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  screenHeight * 0.02, // Restored from 0.015
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            AppStrings.logIn,
                            style: TextStyle(
                              fontSize: AppConstants.mediumFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                  SizedBox(height: screenHeight * 0.02), // Restored from 0.015

                  // Sign Up Link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
                    child: Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: AppConstants.smallFontSize,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
