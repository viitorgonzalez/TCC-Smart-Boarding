import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/auth/screens/login_screen.dart';
import 'package:smartboarding_app/features/home/admin_home_screen.dart';
import 'package:smartboarding_app/features/home/student_home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..restoreSession(),
        ),
      ],
      child: const SmartBoardingApp(),
    ),
  );
}

class SmartBoardingApp extends StatelessWidget {
  const SmartBoardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBoarding',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const StudentHomeScreen(),
        '/admin': (_) => const AdminHomeScreen(),
      },
    );
  }
}
