import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';
import 'features/lists/providers/student_list_provider.dart';
import 'features/lists/services/list_service.dart';
import 'features/registration/providers/registration_provider.dart';
import 'features/registration/screens/register_screen.dart';
import 'features/registration/services/institution_service.dart';
import 'features/registration/services/registration_service.dart';

void main() {
  runApp(const SmartBoardingApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class SmartBoardingApp extends StatefulWidget {
  const SmartBoardingApp({super.key});

  @override
  State<SmartBoardingApp> createState() => _SmartBoardingAppState();
}

class _SmartBoardingAppState extends State<SmartBoardingApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _listenForInviteLinks();
  }

  // Convite chega como link externo (e-mail) — precisa interceptar tanto o
  // cold-start (app fechado, abriu pelo link) quanto o app já aberto em
  // segundo plano (RN13).
  void _listenForInviteLinks() {
    _appLinks.getInitialLink().then(_handleLink);
    _linkSub = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri? uri) {
    if (uri == null || !uri.path.startsWith('/register/')) return;
    final token = uri.pathSegments.last;
    // Quem clica o link do convite não está logado — RegisterScreen nunca
    // está dentro da árvore de providers do AdminHomeScreen, então precisa
    // do próprio RegistrationProvider aqui, não herdado de lugar nenhum.
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => RegistrationProvider(RegistrationService(), InstitutionService()),
          child: RegisterScreen(token: token),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

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
        navigatorKey: navigatorKey,
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
