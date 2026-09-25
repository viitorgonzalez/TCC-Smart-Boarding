import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/async_builder.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../profile/providers/me_provider.dart';
import '../profile/screens/profile_screen.dart';
import '../lists/models/list_with_enrollment.dart';
import '../lists/providers/student_list_provider.dart';
import 'widgets/student_list_card.dart';

class MyRouteScreen extends StatelessWidget {
  const MyRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de hoje')),
      body: SafeArea(
        child: Consumer2<StudentListProvider, MeProvider>(
          builder: (context, provider, me, _) => AsyncBuilder(
            value: provider.state,
            onRetry: provider.load,
            builder: (items) => RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: EmptyState(
                        icon: Icons.event_busy,
                        title: 'Nenhuma lista disponível hoje',
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: StudentListCard(
                          item: item,
                          missingProfile: me.faltando,
                          onEnter: (tripType) =>
                              _enter(context, provider, item, tripType),
                          onLeave: () => _leave(context, provider, item),
                          onFixProfile: () => _abrirPerfil(context, me),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Recarrega o /me na volta: quem foi preencher o que faltava precisa ver o
  /// botão voltar sem fechar e reabrir a tela.
  Future<void> _abrirPerfil(BuildContext context, MeProvider me) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    await me.load();
  }

  Future<void> _enter(
    BuildContext context,
    StudentListProvider provider,
    ListWithEnrollment item,
    String tripType,
  ) async {
    try {
      await provider.enter(item.list.id, tripType);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, AppException.fromError(e));
      }
    }
  }

  Future<void> _leave(
    BuildContext context,
    StudentListProvider provider,
    ListWithEnrollment item,
  ) async {
    try {
      await provider.leave(item.list.id);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, AppException.fromError(e));
      }
    }
  }
}
