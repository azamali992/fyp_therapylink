import 'package:flutter/material.dart';
import 'package:therapylink/Views/signup.dart';

import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

import 'package:therapylink/Views/login.dart';

class Welcomepage extends StatelessWidget {
  const Welcomepage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundGradientStart,
      body: Center(
        child: Container(
          width: screenWidth * 1.2,
          height: screenHeight * 1.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
            gradient: const LinearGradient(
              colors: [
                AppColors.backgroundGradientStart,
                AppColors.backgroundGradientEnd,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppConstants.largePadding),

              // Title
              // const Text(
              //   AppStrings.appTitle,
              //   style: TextStyle(
              //     fontSize: AppConstants.extraLargeFontSize,
              //     fontWeight: FontWeight.bold,
              //     color: AppColors.textWhite,
              //   ),
              //   textAlign: TextAlign.center,
              // ),

              // const SizedBox(height: AppConstants.largePadding),

              // Image
              SizedBox(
                width: screenWidth * 0.8, // Adjust width dynamically
                height: screenHeight * 0.3, // Adjust height dynamically
                child: Image.asset(
                  'assets/therapylink_logofull.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Row for Social Media Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Facebook Button
                  Container(
                    width: AppConstants.largeIconSize * 1.5,
                    height: AppConstants.largeIconSize * 1.5,
                    decoration: const BoxDecoration(
                      color: AppColors.semiTransparentWhite,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.facebook),
                      color: AppColors.facebookBlue,
                      iconSize: AppConstants.largeIconSize,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),

                  // Google Button
                  Container(
                    width: AppConstants.largeIconSize * 1.5,
                    height: AppConstants.largeIconSize * 1.5,
                    decoration: const BoxDecoration(
                      color: AppColors.semiTransparentWhite,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: SizedBox(
                        width: AppConstants.mediumIconSize,
                        height: AppConstants.mediumIconSize,
                        child: Image.asset(
                          'assets/nobg google.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      iconSize: AppConstants.mediumIconSize,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),

                  // Apple Button
                  Container(
                    width: AppConstants.largeIconSize * 1.5,
                    height: AppConstants.largeIconSize * 1.5,
                    decoration: const BoxDecoration(
                      color: AppColors.semiTransparentWhite,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.apple),
                      color: AppColors.textWhite,
                      iconSize: AppConstants.largeIconSize,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Divider with "OR"
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.dividerColor,
                      thickness: AppConstants.dividerThickness,
                      endIndent: AppConstants.smallPadding,
                    ),
                  ),
                  Text(
                    AppStrings.or,
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppConstants.mediumFontSize,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.dividerColor,
                      thickness: AppConstants.dividerThickness,
                      indent: AppConstants.smallPadding,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.largePadding),

              // Email Signup Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.semiTransparentWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: AppConstants.smallPadding,
                  ),
                ),
                child: const Text(
                  AppStrings.signUpWithEmail,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: AppConstants.mediumFontSize,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Login Link
              TextButton(
                onPressed: () {
                  // Navigate to Login Page
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()));
                },
                child: const Text(
                  AppStrings.existingAccount,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: AppConstants.mediumFontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
