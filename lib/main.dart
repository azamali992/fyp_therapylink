import 'package:flutter/material.dart';
import 'package:therapylink/auth.dart';
import 'package:therapylink/Views/onboardingpage.dart';
import 'package:therapylink/Views/bottomnav.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TherapyLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Error checking authentication state'),
            ),
          );
        }

        final bool isLoggedIn = snapshot.data ?? false;
        return isLoggedIn
            ? const GoogleBottomBar()
            : const ConcentricAnimationOnboarding();
      },
    );
  }
}
