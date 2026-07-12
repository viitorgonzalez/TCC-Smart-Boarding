import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../../lists/models/daily_list_model.dart';
import '../../lists/services/list_service.dart';
import '../providers/driver_provider.dart';
import '../services/driver_service.dart';

const _defaultMessage =
    'O ônibus está saindo da rodoviária, embarque em instantes!';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverProvider(ListService(), DriverService())..load(),
      child: const _DriverShell(),
    );
  }
}

class _DriverShell extends StatelessWidget {
  const _DriverShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (lists) => lists.isEmpty
              ? const _EmptyState()
              : _DepartureForm(provider: provider, lists: lists),
        ),
      ),
    );
  }
}

class _DepartureForm extends StatefulWidget {
  final DriverProvider provider;
  final List<DailyList> lists;
  const _DepartureForm({required this.provider, required this.lists});

  @override
  State<_DepartureForm> createState() => _DepartureFormState();
}

class _DepartureFormState extends State<_DepartureForm> {
  final _messageCtrl = TextEditingController(text: _defaultMessage);

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final selected = widget.provider.selected;
    if (selected == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar envio'),
        content: Text(
          'Enviar a notificação de saída para os inscritos ativos da rota '
          '"${selected.routeName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final notified =
          await widget.provider.sendDeparture(_messageCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notificação enviada para $notified aluno(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao enviar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final selected = provider.selected;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<DailyList>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Lista / Rota do dia'),
          items: widget.lists
              .map((l) => DropdownMenuItem(
                    value: l,
                    child:
                        Text('${l.routeName} · ${l.totalEntries} inscrito(s)'),
                  ))
              .toList(),
          onChanged: (l) => l == null ? null : provider.select(l),
        ),
        const SizedBox(height: 16),
        if (selected != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text('${selected.totalEntries} inscrito(s) ativo(s)'),
              subtitle: Text('Rota: ${selected.routeName} · ${selected.date}'),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Mensagem',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: provider.sending ? null : _confirmAndSend,
          icon: provider.sending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Enviar notificação de saída'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Nenhuma lista disponível hoje'),
          ],
        ),
      );
}
