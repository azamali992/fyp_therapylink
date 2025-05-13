import 'package:flutter/material.dart';
import 'package:therapylink/Views/bottomnav.dart';
import 'package:therapylink/Views/login.dart';
import 'auth.dart';
import 'Views/professional_dashboard.dart';
import 'utils/user_role.dart';

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
        if (isLoggedIn) {
          return FutureBuilder<UserRole?>(
            future: AuthService.getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (roleSnapshot.hasError || roleSnapshot.data == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Error checking user role'),
                  ),
                );
              }

              final UserRole role = roleSnapshot.data!;
              if (role == UserRole.MentalHealthProfessional) {
                return const ProfessionalDashboard();
              } else {
                return const GoogleBottomBar(); // Navigate to MainMenu for regular users
              }
            },
          );
        } else {
          return const LoginPage(); // Replace with your login page
        }
      },
    );
  }
}
