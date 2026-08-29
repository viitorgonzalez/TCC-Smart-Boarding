import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/warning_model.dart';
import '../services/warning_service.dart';

/// Advertências por não se inscrever no prazo. O aluno vê as próprias; o admin
/// vê todas e pode remover — advertência aplicada por engano precisa sair.
class WarningsScreen extends StatefulWidget {
  final bool canManage;
  const WarningsScreen({super.key, this.canManage = false});

  @override
  State<WarningsScreen> createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen> {
  final _service = WarningService();
  List<WarningModel>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final items = widget.canManage
          ? await _service.getWarnings()
          : await _service.getMine();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppException.fromError(e));
    }
  }

  Future<void> _delete(WarningModel warning) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover advertência?'),
        content: Text(
          'A advertência de ${warning.studentName} some do sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.delete(warning.id);
      if (mounted) showSuccessSnackBar(context, 'Advertência removida');
      await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advertências')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            EmptyState(
              icon: Icons.verified_outlined,
              title: widget.canManage
                  ? 'Nenhuma advertência registrada'
                  : 'Você não tem advertências',
              subtitle: widget.canManage
                  ? null
                  : 'Confirme sua presença dentro do horário e continua assim.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _WarningCard(
          warning: items[i],
          showName: widget.canManage,
          onDelete: widget.canManage ? () => _delete(items[i]) : null,
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final WarningModel warning;
  final bool showName;
  final VoidCallback? onDelete;

  const _WarningCard({
    required this.warning,
    required this.showName,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(
              Icons.report_gmailerrorred_outlined,
              color: AppColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showName ? warning.studentName : 'Advertência',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(warning.reason),
                const SizedBox(height: 8),
                Text(
                  [
                    if (warning.listDate != null)
                      'Lista de ${formatDate(warning.listDate)}',
                    formatDateTime(warning.createdAt),
                    if (warning.issuedBy != null) 'por ${warning.issuedBy}',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.textSecondary,
              tooltip: 'Remover',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
