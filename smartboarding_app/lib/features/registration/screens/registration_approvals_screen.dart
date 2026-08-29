import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/async_value.dart';
import '../models/registration_request_model.dart';
import '../providers/registration_provider.dart';
import '../widgets/registration_actions.dart';
import 'registration_detail_screen.dart';

// Sem estado próprio — mesmo padrão de RoutesScreen. O load inicial da lista
// de pendentes é responsabilidade de quem cria o RegistrationProvider
// (`..loadPending()` no MultiProvider do AdminHomeScreen), não desta tela.
class RegistrationApprovalsScreen extends StatelessWidget {
  const RegistrationApprovalsScreen({super.key});

  // O push sai no Navigator raiz, acima do MultiProvider do AdminHomeScreen —
  // sem repassar a instância, a tela de detalhe não acha o RegistrationProvider.
  void _openDetail(BuildContext context, RegistrationRequestModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<RegistrationProvider>(),
          child: RegistrationDetailScreen(request: item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, _) {
          return switch (provider.pending) {
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
            AsyncError(:final message) => Center(child: Text(message)),
            AsyncData(:final value) when value.isEmpty => RefreshIndicator(
              onRefresh: provider.loadPending,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhuma solicitação pendente')),
                ],
              ),
            ),
            AsyncData(:final value) => RefreshIndicator(
              onRefresh: provider.loadPending,
              child: ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final item = value[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      onTap: () => _openDetail(context, item),
                      title: Text(item.fullName ?? item.email),
                      subtitle: Text(
                        item.institutionName != null
                            ? '${item.email} · ${item.institutionName}'
                            : item.email,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () => confirmApprove(context, item.id),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                            ),
                            onPressed: () => promptReject(context, item.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          };
        },
      ),
    );
  }
}
