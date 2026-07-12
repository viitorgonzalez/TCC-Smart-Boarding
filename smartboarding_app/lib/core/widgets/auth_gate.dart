import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/driver/screens/driver_home_screen.dart';
import '../../features/home/admin_home_screen.dart';
import '../../features/home/student_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            if (auth.isAdmin) return const AdminHomeScreen();
            if (auth.isDriver) return const DriverHomeScreen();
            return const StudentHomeScreen();
        }
      },
    );
  }
}
