import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapylink/Views/bottomnav.dart';
import 'package:therapylink/Views/login.dart';
import 'auth.dart' as auth;
import 'Views/professional_dashboard.dart';
import 'utils/user_role.dart';
import 'dart:core';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    print('Firebase initialization error: $e');
  }
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Replaces manual login check
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage(); // User is not logged in
        }

        // User is logged in – now get their role from Firestore
        return FutureBuilder<UserRole?>(
          future: auth.AuthService.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasError || roleSnapshot.data == null) {
              return const Scaffold(
                body: Center(child: Text('Error fetching user role')),
              );
            }

            final role = roleSnapshot.data!;
            if (role == UserRole.MentalHealthProfessional) {
              return const ProfessionalDashboard();
            } else {
              return const GoogleBottomBar(); // Replace with your actual home for regular users
            }
          },
        );
      },
    );
  }
}