import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/profile/providers/me_provider.dart';
import 'features/membership/providers/membership_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_navigator.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => MeProvider()..load()),

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
        themeMode: ThemeMode.light,
        home: const AuthGate(),
      ),
    );
  }
}
