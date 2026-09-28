import 'package:flutter/material.dart';

/// Chave do Navigator raiz.
///
/// Existe pra quem precisa navegar de fora da árvore de widgets — hoje só o
/// tratamento de sessão expirada, que roda num interceptor do Dio e precisa
/// desempilhar as telas abertas sobre o [AuthGate].
final navigatorKey = GlobalKey<NavigatorState>();
