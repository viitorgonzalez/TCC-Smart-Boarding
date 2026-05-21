import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/auth/screens/login_screen.dart';
import 'package:smartboarding_app/features/home/admin_home_screen.dart';
import 'package:smartboarding_app/features/home/student_home_screen.dart';

/// Redireciona o usuário para a tela correta com base no estado de autenticação.
///
/// Enquanto a sessão salva está sendo restaurada do armazenamento local,
/// exibe um splash de carregamento para evitar o flash da tela de login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.isAdmin) return const AdminHomeScreen();
    return const StudentHomeScreen();
  }
}
