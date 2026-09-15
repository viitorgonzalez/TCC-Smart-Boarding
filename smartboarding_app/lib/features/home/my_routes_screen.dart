import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/async_value.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../lists/providers/student_list_provider.dart';
import '../membership/providers/membership_provider.dart';
import '../membership/screens/join_route_screen.dart';
import 'my_route_screen.dart';
import '../../core/widgets/app_list_group.dart';

/// As rotas de que o aluno participa, e a porta pra entrar em mais uma.
///
/// O gesto é o do Google Classroom: as turmas de que você faz parte, com um
/// "entrar com código" junto delas. Por isso a ação mora aqui e não escondida
/// noutro canto — é aqui que a pessoa vem procurar quando recebe um código.
class MyRoutesScreen extends StatelessWidget {
  const MyRoutesScreen({super.key});

  Future<void> _entrarComCodigo(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const JoinRouteScreen()));
  }

  /// Abre a lista do dia já com a rota tocada em foco — sem isso, quem tem mais
  /// de uma rota abriria a lista da rota errada.
  void _abrirLista(BuildContext context, String routeId) {
    context.read<MembershipProvider>().select(routeId);
    final listProvider = context.read<StudentListProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: listProvider,
          child: const MyRouteScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas rotas')),
      body: SafeArea(
        child: Consumer<MembershipProvider>(
          builder: (context, provider, _) {
            final rotas = provider.routes;
            final carregando = provider.state is AsyncLoading;
            return RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.vpn_key_outlined,
                              color: AppColors.deepTeal,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entrar em uma rota',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Peça o código ao administrador da sua '
                                    'rota e digite aqui.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const Key('my_routes_join'),
                          onPressed: () => _entrarComCodigo(context),
                          icon: const Icon(Icons.login_outlined),
                          label: const Text('Entrar com código'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (rotas.isEmpty && !carregando)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.alt_route_outlined,
                        title: 'Você ainda não está em nenhuma rota',
                        subtitle:
                            'Assim que entrar com um código, a rota aparece '
                            'aqui e a lista do dia fica disponível.',
                      ),
                    ),
                  // Grupo unico: uma pilha de cartoes fazia cada rota pesar o
                  // mesmo que o bloco de entrar com codigo, que e a acao.
                  AppListGroup(
                    dividerIndent: 68,
                    children: [
                      for (final rota in rotas)
                        AppListItem(
                          leading: const Icon(
                            Icons.directions_bus_outlined,
                            color: AppColors.deepTeal,
                          ),
                          title: rota.name,
                          subtitle: 'Ver a lista de hoje',
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                          onTap: () => _abrirLista(context, rota.id),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
