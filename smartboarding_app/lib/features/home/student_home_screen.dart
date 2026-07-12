import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/async_builder.dart';
import '../lists/models/list_with_enrollment.dart';
import '../lists/providers/student_list_provider.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.token?.fullName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Boarding'),
            if (name.isNotEmpty)
              Text('Olá, $name',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StudentListProvider>().load(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Consumer<StudentListProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (items) => items.isEmpty
              ? const _EmptyListsState()
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ListCard(
                        item: items[i],
                        onToggle: () => _toggle(context, provider, items[i]),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, StudentListProvider provider,
      ListWithEnrollment item) async {
    try {
      await provider.toggle(item.list.id, item.isEnrolled);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Card de lista ────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final ListWithEnrollment item;
  final VoidCallback onToggle;

  const _ListCard({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final list = item.list;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(list.routeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _StatusChip(isOpen: list.isOpen),
            ]),
            const SizedBox(height: 4),
            Text('${list.totalEntries} inscrito(s) · ${formatDate(list.date)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            if (item.isEnrolled) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.check_circle, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text('Você está na lista',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
            ],
            if (list.isOpen) ...[
              const SizedBox(height: 12),
              const _CloseCountdown(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: item.isEnrolled
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                        onPressed: onToggle,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Sair da lista'),
                      )
                    : FilledButton.icon(
                        onPressed: onToggle,
                        icon: const Icon(Icons.add),
                        label: const Text('Entrar na lista'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Contagem regressiva até o fechamento (16:00) ─────────────────────────────

class _CloseCountdown extends StatefulWidget {
  const _CloseCountdown();

  @override
  State<_CloseCountdown> createState() => _CloseCountdownState();
}

class _CloseCountdownState extends State<_CloseCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Recalcula a cada 30s para o contador ficar sempre exato.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = timeUntilListClose();
    final closingSoon = remaining == null;
    final color = closingSoon ? cs.error : cs.primary;
    final text = closingSoon
        ? 'Fechamento às 16:00 — encerrando'
        : 'Fecha em ${humanizeDuration(remaining)} · às 16:00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  const _StatusChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isOpen ? 'Aberta' : 'Fechada',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOpen ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _EmptyListsState extends StatelessWidget {
  const _EmptyListsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Nenhuma lista disponível hoje',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
