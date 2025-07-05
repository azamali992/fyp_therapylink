import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:therapylink/Views/signup.dart';
import 'package:therapylink/Views/professional_dashboard.dart';
// import 'package:therapylink/Views/google_bottom_bar.dart'; // Removed because file does not exist
import '../utils/colors.dart';
import '../utils/strings.dart';
import '../utils/constants.dart';
import 'package:therapylink/auth.dart';
import '../utils/user_role.dart';
// Add this to the imports at the top
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';



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

  // Ensure Firebase is initialized before using it
  Future<void> ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  void _signIn(UserRole expectedRole) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ensureFirebaseInitialized();

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      final user = await AuthService.signInWithEmail(email, password);

      if (user != null) {
        final role = await AuthService.getUserRole(user.uid);

        if (mounted) {
          if (role == expectedRole) {
            if (role == UserRole.MentalHealthProfessional) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('User Dashboard')),
                    body: const Center(child: Text('User dashboard not implemented.')),
                  ),
                ),
              );
            }
          } else {
            setState(() {
              _errorMessage = "Role mismatch. Please log in with the correct account.";
            });
          }
        }
      } else {
        setState(() => _errorMessage = "Invalid email or password.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Login failed. ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _signInWithGoogle({bool isSignUp = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ensureFirebaseInitialized();

    try {
      final user = await AuthService.signInWithGoogle();

      if (user != null) {
        final isNewUser =
            user.metadata.creationTime == user.metadata.lastSignInTime;

        if (isSignUp && isNewUser) {
          await AuthService.saveUserRole(user.uid, UserRole.RegularUser);
        }

        final role = await AuthService.getUserRole(user.uid);

        if (mounted) {
          if (role == UserRole.MentalHealthProfessional) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfessionalDashboard()),
            );
          } else if (role == UserRole.RegularUser) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('User Dashboard')),
                  body: const Center(child: Text('User dashboard not implemented.')),
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = "No role assigned. Contact support.";
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = isSignUp
              ? "Google Sign Up failed."
              : "Google Sign In failed.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Google Sign-In error: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
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
                  SizedBox(height: screenHeight * 0.06),
                  Center(
                    child: SizedBox(
                      width: screenWidth * 0.7,
                      height: screenHeight * 0.15,
                      child: Image.asset(
                        'assets/therapylink_logofull.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
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
                  SizedBox(height: screenHeight * 0.06),
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(AppConstants.largeBorderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                              AppConstants.largeBorderRadius),
                          border:
                          Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
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
                  _isLoading
                      ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                    onPressed: () =>
                        _signIn(UserRole.MentalHealthProfessional),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login as Professional',
                      style: TextStyle(
                        fontSize: AppConstants.mediumFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _isLoading
                      ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                    onPressed: () => _signIn(UserRole.RegularUser),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login as User',
                      style: TextStyle(
                        fontSize: AppConstants.mediumFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  /// 🔽= Google Sign-In & Sign-Up Buttons
                  SignInButton(
                    Buttons.Google,
                    text: "Sign In with Google",
                    onPressed: () async {
                      await _signInWithGoogle(isSignUp: false);
                    },
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  SignInButton(
                    Buttons.Google,
                    text: "Sign Up with Google",
                    onPressed: () async {
                      await _signInWithGoogle(isSignUp: true);
                    },
                  ),

                  SizedBox(height: screenHeight * 0.02),
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