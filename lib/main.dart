import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:therapylink/bloc/chat_bloc.dart';

import 'firebase_options.dart';
import 'Views/font_size_provider.dart';
import 'Views/login.dart';
import 'auth.dart' as auth;
import 'Views/professional_dashboard.dart';
import 'utils/user_role.dart';
import 'Views/bottomnav.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final textSize = prefs.getDouble('textSize') ?? 16.0;

  runApp(
    ChangeNotifierProvider(
      create: (_) => FontSizeProvider(textSize),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return MaterialApp(
      title: 'TherapyLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSizeProvider.textSize),
          bodyMedium: TextStyle(fontSize: fontSizeProvider.textSize),
        ),
        useMaterial3: true,
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
      ),
      home: Builder(
        builder: (context) {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final user = snapshot.data;

              if (user == null) {
                return const LoginPage();
              }

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
                  // Provide ChatBloc globally for all children
                  return BlocProvider(
                    create: (_) => ChatBloc(userId: user.uid),
                    child: role == UserRole.MentalHealthProfessional
                        ? const ProfessionalDashboard()
                        : const GoogleBottomBar(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

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
              return const GoogleBottomBar();
            }
          },
        );
      },
    );
  }
}
