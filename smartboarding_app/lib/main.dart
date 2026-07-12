import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';
import 'features/lists/providers/student_list_provider.dart';
import 'features/lists/services/list_service.dart';

void main() {
  runApp(const SmartBoardingApp());
}

class SmartBoardingApp extends StatelessWidget {
  const SmartBoardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth — global, persiste toda a sessão
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),

        // StudentListProvider recebe o email via ProxyProvider
        // assim que o login é concluído
        ChangeNotifierProxyProvider<AuthProvider, StudentListProvider>(
          create: (_) => StudentListProvider(ListService()),
          update: (_, auth, prev) {
            final email = auth.token?.email ?? '';
            prev!.setUserEmail(email);
            return prev;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Smart Boarding',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}
