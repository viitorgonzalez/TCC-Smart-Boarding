import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/core/widgets/auth_gate.dart';
import 'package:smartboarding_app/features/auth/screens/login_screen.dart';
import 'package:smartboarding_app/features/home/admin_home_screen.dart';
import 'package:smartboarding_app/features/home/student_home_screen.dart';
import 'package:smartboarding_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      // AuthGate decide a rota inicial com base na sessão salva.
      // Evita o flash de login quando o usuário já está autenticado.
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const StudentHomeScreen(),
        '/admin': (_) => const AdminHomeScreen(),
      },
    );
  }
}
