import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/async_value.dart';
import '../providers/registration_provider.dart';

// Sem estado próprio — mesmo padrão de RoutesScreen. O load inicial da lista
// de pendentes é responsabilidade de quem cria o RegistrationProvider
// (Task 14 Step 3, `..loadPending()` no MultiProvider do AdminHomeScreen),
// não desta tela.
class RegistrationApprovalsScreen extends StatelessWidget {
  const RegistrationApprovalsScreen({super.key});

  Future<void> _confirmAndAct(BuildContext context, String id, {required bool approve}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Aprovar cadastro?' : 'Negar cadastro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<RegistrationProvider>();
    if (approve) {
      await provider.approve(id);
    } else {
      await provider.reject(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, _) {
          return switch (provider.pending) {
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
            AsyncError(:final message) => Center(child: Text(message)),
            AsyncData(:final value) when value.isEmpty =>
              const Center(child: Text('Nenhuma solicitação pendente')),
            AsyncData(:final value) => ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final item = value[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(item.fullName ?? item.email),
                      subtitle: Text(item.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            onPressed: () => _confirmAndAct(context, item.id, approve: true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () => _confirmAndAct(context, item.id, approve: false),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          };
        },
      ),
    );
  }
}
