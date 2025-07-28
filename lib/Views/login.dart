import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:therapylink/Views/signup.dart';
import 'package:therapylink/Views/professional_dashboard.dart';
import '../utils/colors.dart';
import '../utils/strings.dart';
import '../utils/constants.dart';
import 'package:therapylink/auth.dart';
import '../utils/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:therapylink/Views/bottomnav.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoadingProfessional = false;
  bool _isLoadingUser = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _emailError = false;
  bool _passwordError = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  void _signIn(UserRole expectedRole) async {
    setState(() {
      _errorMessage = null;
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.isEmpty;
    });

    if (_emailError || _passwordError) return;

    setState(() {
      if (expectedRole == UserRole.MentalHealthProfessional) {
        _isLoadingProfessional = true;
      } else {
        _isLoadingUser = true;
      }
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => role == UserRole.MentalHealthProfessional
                    ? const ProfessionalDashboard()
                    : const GoogleBottomBar(),
              ),
            );
          } else {
            setState(() {
              _errorMessage =
                  "Role mismatch. Please log in with the correct account.";
            });
          }
        }
      } else {
        setState(() => _errorMessage = "Invalid email or password.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Login failed. ${e.toString()}");
    } finally {
      setState(() {
        _isLoadingProfessional = false;
        _isLoadingUser = false;
      });
    }
  }

  void _showPasswordResetDialog() async {
    final TextEditingController resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: TextField(
            controller: resetEmailController,
            decoration: const InputDecoration(hintText: "Enter your email"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Send"),
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Reset link sent to your email.")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                }
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _signInWithGoogle({bool isSignUp = false}) async {
    setState(() {
      _isLoadingUser = true;
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => role == UserRole.MentalHealthProfessional
                  ? const ProfessionalDashboard()
                  : const GoogleBottomBar(),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage =
              isSignUp ? "Google Sign Up failed." : "Google Sign In failed.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Google Sign-In error: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoadingUser = false);
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
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.04,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: screenHeight * 0.06),
                      // Logo with bounce effect
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        duration: const Duration(seconds: 2),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Center(
                              child: Hero(
                                tag: 'logo',
                                child: SizedBox(
                                  width: screenWidth * 0.7,
                                  height: screenHeight * 0.15,
                                  child: Image.asset(
                                    'assets/therapylink_logofull.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      // Welcome text with shimmer effect
                      const ShimmerText(
                        text: AppStrings.loginToTherapyLink,
                        style: TextStyle(
                          fontSize: AppConstants.largeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        AppStrings.welcomeMessage,
                        style: TextStyle(
                          fontSize: AppConstants.mediumFontSize,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.06),

                      // Frosted glass login container with subtle elevation
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - _fadeAnimation.value) * 20),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.largeBorderRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: -5,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.largeBorderRadius),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    padding: EdgeInsets.all(screenWidth * 0.06),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.largeBorderRadius),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Email field
                                        TextField(
                                          controller: _emailController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                AppConstants.mediumFontSize,
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                AppStrings.emailPlaceholder,
                                            labelStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize:
                                                  AppConstants.smallFontSize,
                                            ),
                                            prefixIcon: const Icon(Icons.email,
                                                color: Colors.white70),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: _emailError
                                                    ? Colors.redAccent
                                                    : Colors.white
                                                        .withOpacity(0.3),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: _emailError
                                                    ? Colors.redAccent
                                                    : Colors.white,
                                                width: 2.0,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor:
                                                Colors.black.withOpacity(0.1),
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.02),

                                        // Password field
                                        TextField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                AppConstants.mediumFontSize,
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                AppStrings.passwordPlaceholder,
                                            labelStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize:
                                                  AppConstants.smallFontSize,
                                            ),
                                            prefixIcon: const Icon(Icons.lock,
                                                color: Colors.white70),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: _passwordError
                                                    ? Colors.redAccent
                                                    : Colors.white
                                                        .withOpacity(0.3),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: _passwordError
                                                    ? Colors.redAccent
                                                    : Colors.white,
                                                width: 2.0,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor:
                                                Colors.black.withOpacity(0.1),
                                          ),
                                        ),

                                        // Forgot password button
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: _showPasswordResetDialog,
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5),
                                            ),
                                            child: Text(
                                              "Forgot Password?",
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize:
                                                    AppConstants.smallFontSize,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: Colors.white
                                                    .withOpacity(0.5),
                                              ),
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
                        },
                      ),

                      // Error message
                      if (_errorMessage != null)
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.02),
                          child: AnimatedOpacity(
                            opacity: _errorMessage != null ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.5)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: screenHeight * 0.04),

                      // Login as Professional button
                      _isLoadingProfessional
                          ? const Center(
                              child: SpinKitThreeBounce(
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 130, 60, 229),
                                    Color.fromARGB(255, 93, 25, 173),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 93, 25, 173)
                                            .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    _signIn(UserRole.MentalHealthProfessional),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius),
                                  ),
                                ),
                                child: const Text(
                                  'Login as Professional',
                                  style: TextStyle(
                                    fontSize: AppConstants.mediumFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                      SizedBox(height: screenHeight * 0.02),

                      // Login as User button
                      _isLoadingUser
                          ? const Center(
                              child: SpinKitThreeBounce(
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 75, 13, 177),
                                    Color.fromARGB(255, 41, 6, 100),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 41, 6, 100)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _signIn(UserRole.RegularUser),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius),
                                  ),
                                ),
                                child: const Text(
                                  'Login as User',
                                  style: TextStyle(
                                    fontSize: AppConstants.mediumFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                      // SizedBox(height: screenHeight * 0.03),

                      // // Google sign-in buttons
                      // Container(
                      //   decoration: BoxDecoration(
                      //     borderRadius:
                      //         BorderRadius.circular(AppConstants.borderRadius),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withOpacity(0.2),
                      //         blurRadius: 8,
                      //         offset: const Offset(0, 4),
                      //       ),
                      //     ],
                      //   ),
                      //   child: SignInButton(
                      //     Buttons.Google,
                      //     text: "Sign In with Google",
                      //     onPressed: () async {
                      //       await _signInWithGoogle(isSignUp: false);
                      //     },
                      //   ),
                      // ),

                      // SizedBox(height: screenHeight * 0.015),

                      // Container(
                      //   decoration: BoxDecoration(
                      //     borderRadius:
                      //         BorderRadius.circular(AppConstants.borderRadius),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withOpacity(0.2),
                      //         blurRadius: 8,
                      //         offset: const Offset(0, 4),
                      //       ),
                      //     ],
                      //   ),
                      //   child: SignInButton(
                      //     Buttons.Google,
                      //     text: "Sign Up with Google",
                      //     onPressed: () async {
                      //       await _signInWithGoogle(isSignUp: true);
                      //     },
                      //   ),
                      // ),

                      // SizedBox(height: screenHeight * 0.02),

                      // Sign up link
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom ShaderMask widget for text shimmer effect
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  _ShimmerTextState createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [Colors.white, Colors.white70, Colors.white],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform:
                  GradientRotation(_shimmerController.value * 2 * 3.14159),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style.copyWith(color: Colors.white),
            textAlign: widget.textAlign,
          ),
        );
      },
    );
  }
}