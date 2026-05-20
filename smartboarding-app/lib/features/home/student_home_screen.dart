import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBoarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Olá, ${auth.currentUser?.fullName ?? ''}!\nMódulo de listas em breve.'),
      ),
    );
  }
}
