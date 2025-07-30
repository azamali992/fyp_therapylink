import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:therapylink/Views/login.dart';
import 'package:therapylink/Views/psychologist_signup.dart';
import '../utils/colors.dart';
import 'package:therapylink/auth.dart';
import '../utils/user_role.dart';
import '../utils/constants.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  // XFile? _pickedImage;
  String? _selectedGender;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

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
    _ageController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _selectDOB(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.backgroundGradientStart,
              onPrimary: Colors.white,
              surface: Color.fromARGB(255, 55, 13, 104),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
                backgroundColor: Color.fromARGB(255, 30, 10, 60)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      final age = DateTime.now().year - picked.year;
      _ageController.text = age.toString();
    }
  }

  void _signUp(UserRole role) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final dob = _dobController.text;
      final gender = _selectedGender;
      final phone = _phoneController.text;
      final username = _usernameController.text.trim();

      // 🔁 STEP: Check if username is already taken in Firestore
      final isTaken = await isUsernameTaken(username);
      if (isTaken) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Username already taken';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already taken')),
        );
        return; // ⛔ Stop execution if taken
      }

      final user = await AuthService.signUpWithEmail(email, password);

      if (user != null) {
        await AuthService.saveUserProfile(
          user.uid,
          role,
          gender: gender ?? '',
          dob: dob,
          age: _ageController.text,
          phone: phone,
          username: username,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        setState(() {
          _errorMessage = "Failed to create account. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
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
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.03,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button with animation
                      Align(
                        alignment: Alignment.topLeft,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Logo with bounce effect
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        duration: const Duration(seconds: 2),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Hero(
                              tag: 'logo',
                              child: SizedBox(
                                width: screenWidth * 0.5,
                                height: screenHeight * 0.1,
                                child: Image.asset(
                                  'assets/therapylink_logofull.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Title with shimmer effect
                      const ShimmerText(
                        text: "Create Account",
                        style: TextStyle(
                          fontSize: AppConstants.largeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      Text(
                        "Please fill in the details to create your account",
                        style: TextStyle(
                          fontSize: AppConstants.smallFontSize,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Form inside a frosted glass container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppConstants.largeBorderRadius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.largeBorderRadius),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: -5,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username field
                                  _buildInputField(
                                    controller: _usernameController,
                                    label: "Username",
                                    prefixIcon: Icons.person,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Please enter a username";
                                      }
                                      if (value.trim().length < 3) {
                                        return "Username must be at least 3 characters";
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                          .hasMatch(value)) {
                                        return "Only letters, numbers, and underscores allowed";
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Profile Picture Picker
                                  // Center(
                                  //   child: GestureDetector(
                                  //     onTap: () async {
                                  //       final ImagePicker picker =
                                  //           ImagePicker();
                                  //       final XFile? image =
                                  //           await picker.pickImage(
                                  //               source: ImageSource.gallery);
                                  //       if (image != null) {
                                  //         setState(() {
                                  //           _pickedImage = image;
                                  //         });
                                  //       }
                                  //     },
                                  //     child: Container(
                                  //       height: 100,
                                  //       width: 100,
                                  //       decoration: BoxDecoration(
                                  //         shape: BoxShape.circle,
                                  //         border:
                                  //             Border.all(color: Colors.white54),
                                  //         image: _pickedImage != null
                                  //             ? DecorationImage(
                                  //                 image: FileImage(
                                  //                     File(_pickedImage!.path)),
                                  //                 fit: BoxFit.cover,
                                  //               )
                                  //             : null,
                                  //         color: Colors.white10,
                                  //       ),
                                  //       child: _pickedImage == null
                                  //           ? const Icon(Icons.add_a_photo,
                                  //               color: Colors.white70)
                                  //           : null,
                                  //     ),
                                  //   ),
                                  // ),
                                  // SizedBox(height: screenHeight * 0.02),

                                  // Email field
                                  _buildInputField(
                                    controller: _emailController,
                                    label: "Email",
                                    prefixIcon: Icons.email,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your email";
                                      }
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value)) {
                                        return "Please enter a valid email";
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Password field
                                  _buildPasswordField(
                                    controller: _passwordController,
                                    label: "Password",
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter a password";
                                      }
                                      if (value.length < 6) {
                                        return "Password must be at least 6 characters";
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Date of birth field with icon button
                                  InkWell(
                                    onTap: () => _selectDOB(context),
                                    child: IgnorePointer(
                                      child: _buildInputField(
                                        controller: _dobController,
                                        label: "Date of Birth",
                                        prefixIcon: Icons.calendar_today,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please enter your date of birth";
                                          }
                                          return null;
                                        },
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.calendar_month,
                                              color: Colors.white70),
                                          onPressed: () => _selectDOB(context),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Age field
                                  _buildInputField(
                                    controller: _ageController,
                                    label: "Age",
                                    prefixIcon: Icons.person_outline,
                                    keyboardType: TextInputType.number,
                                    enabled: false,
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Gender dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedGender,
                                      dropdownColor:
                                          const Color.fromARGB(255, 40, 10, 80),
                                      decoration: const InputDecoration(
                                        labelText: "Gender",
                                        labelStyle:
                                            TextStyle(color: Colors.white70),
                                        prefixIcon: Icon(Icons.person,
                                            color: Colors.white70),
                                        border: InputBorder.none,
                                      ),
                                      style:
                                          const TextStyle(color: Colors.white),
                                      items: [
                                        'Male',
                                        'Female',
                                        'Other',
                                        'Prefer not to say'
                                      ].map((String gender) {
                                        return DropdownMenuItem<String>(
                                          value: gender,
                                          child: Text(gender),
                                        );
                                      }).toList(),
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedGender = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please select your gender";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Phone number field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: IntlPhoneField(
                                      controller: _phoneController,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: "Phone Number",
                                        labelStyle: const TextStyle(
                                            color: Colors.white70),
                                        prefixIcon: const Icon(Icons.phone,
                                            color: Colors.white70),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.3)),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.3)),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Colors.white),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                      dropdownTextStyle:
                                          const TextStyle(color: Colors.white),
                                      dropdownIcon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.white),
                                      dropdownDecoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 40, 10, 80),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

                      SizedBox(height: screenHeight * 0.03),

                      // Sign up buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildSignupButton(
                              label: "Sign Up as User",
                              onPressed: () => _signUp(UserRole.RegularUser),
                              gradientColors: const [
                                Color.fromARGB(255, 75, 13, 177),
                                Color.fromARGB(255, 41, 6, 100),
                              ],
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: _buildSignupButton(
                      //         label: "Sign Up as Professional",
                      //         onPressed: () =>
                      //             _signUp(UserRole.MentalHealthProfessional),
                      //         gradientColors: const [
                      //           Color.fromARGB(255, 130, 60, 229),
                      //           Color.fromARGB(255, 93, 25, 173),
                      //         ],
                      //         isLoading: _isLoading,
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      SizedBox(height: screenHeight * 0.02),

                      // Psychologist signup button
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Register as Psychologist",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: AppConstants.smallFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PsychologistSignUpPage()),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Login link
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        },
                        child: Text(
                          "Already have an account? Login",
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

  // Helper method to build input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(prefixIcon, color: Colors.white70),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
      validator: validator,
    );
  }

  // Helper method to build password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
      validator: validator,
    );
  }

  // Helper method to build signup buttons
  Widget _buildSignupButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white60,
          disabledBackgroundColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: AppConstants.mediumFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

Future<bool> isUsernameTaken(String username) async {
  final query = await FirebaseFirestore.instance
      .collection('users')
      .where('username', isEqualTo: username.trim())
      .get();
  return query.docs.isNotEmpty;
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
