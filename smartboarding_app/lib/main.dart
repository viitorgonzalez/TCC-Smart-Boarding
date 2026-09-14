import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/membership/providers/membership_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';
import 'features/lists/providers/student_list_provider.dart';
import 'features/lists/services/list_service.dart';

void main() {
  runApp(const SmartBoardingApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class SmartBoardingApp extends StatelessWidget {
  const SmartBoardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth — global, persiste toda a sessão
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),

        // Rotas do aluno: recarrega a cada troca de sessao, senao o proximo a
        // logar herdaria as rotas do anterior.
        ChangeNotifierProxyProvider<AuthProvider, MembershipProvider>(
          create: (_) => MembershipProvider(),
          update: (_, auth, prev) {
            if (auth.status == AuthStatus.authenticated) prev!.load();
            return prev!;
          },
        ),

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
        navigatorKey: navigatorKey,
        title: 'Smart Boarding',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // O Figma desenhou só o tema claro; deixar seguir o sistema faria o
        // app abrir escuro e fora do desenho em metade dos aparelhos.
        themeMode: ThemeMode.light,
        home: const AuthGate(),
      ),
    );
  }
}
