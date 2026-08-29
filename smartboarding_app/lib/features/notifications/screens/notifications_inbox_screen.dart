import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/notice_board.dart';

/// Push é entrega, não registro: quem estava offline não saberia do aviso.
class NotificationsInboxScreen extends StatefulWidget {
  /// Admin ganha seleção e exclusão; aluno só lê.
  final bool canManage;

  const NotificationsInboxScreen({super.key, this.canManage = false});

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  late Future<List<NotificationModel>> _future;
  final _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _future = NotificationService().getNotifications();
  }

  Future<void> _reload() async {
    setState(() {
      _selected.clear();
      _future = NotificationService().getNotifications();
    });
    await _future;
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          count == 1 ? 'Apagar este aviso?' : 'Apagar $count avisos?',
        ),
        content: const Text('Eles somem também da caixa dos alunos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await NotificationService().deleteNotifications(_selected.toList());
      if (mounted) showSuccessSnackBar(context, 'Aviso(s) apagado(s)');
      await _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<void> _deleteOne(NotificationModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar este aviso?'),
        content: Text('"${item.title}" some também da caixa dos alunos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await NotificationService().deleteNotifications([item.id]);
      if (mounted) showSuccessSnackBar(context, 'Aviso apagado');
      await _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selecting
              ? '${_selected.length} selecionado(s)'
              : 'Quadro de avisos',
        ),
        leading: _selecting
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar seleção',
                onPressed: () => setState(_selected.clear),
              )
            : null,
        actions: [
          if (_selecting)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Apagar selecionados',
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<NotificationModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(AppException.fromError(snapshot.error!)),
              );
            }
            final items = snapshot.data ?? const <NotificationModel>[];

            return NoticeBoard(
              onRefresh: _reload,
              notes: items.isEmpty
                  ? const [_EmptyNote()]
                  : [
                      for (final item in items)
                        _PinnedNotice(
                          item: item,
                          canManage: widget.canManage,
                          selecting: _selecting,
                          selected: _selected.contains(item.id),
                          onToggle: () => _toggle(item.id),
                          onDelete: () => _deleteOne(item),
                        ),
                    ],
            );
          },
        ),
      ),
    );
  }
}

/// Um aviso preso no mural. O admin vê o botão de apagar no próprio cartão; o
/// toque longo ainda entra na seleção múltipla, que é como se apaga em lote.
class _PinnedNotice extends StatelessWidget {
  final NotificationModel item;
  final bool canManage;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PinnedNotice({
    required this.item,
    required this.canManage,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = item.expired ? AppColors.textSecondary : AppColors.charcoal;

    return NoticeNote(
      seed: item.id,
      faded: item.expired,
      selected: selected,
      accent: selected ? AppColors.danger : null,
      onTap: canManage && selecting ? onToggle : null,
      onLongPress: canManage ? onToggle : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canManage && selecting)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected
                        ? AppColors.deepTeal
                        : AppColors.textSecondary,
                  ),
                ),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(color: muted),
                ),
              ),
              if (canManage && !selecting)
                // Margem negativa: o alvo de toque continua com 40px, mas o
                // ícone alinha com a borda do texto em vez de afastá-lo.
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.danger,
                      tooltip: 'Apagar aviso',
                      onPressed: onDelete,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.45,
              color: muted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                item.expired ? Icons.history_toggle_off : Icons.schedule,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.expired
                      ? 'Expirado · ${formatDateTime(item.createdAt)}'
                      : formatDateTime(item.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (!item.isForEveryone)
                const Tooltip(
                  message: 'Só para quem pega esta rota',
                  child: Icon(
                    Icons.route_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mural vazio também é um mural: um bilhete dizendo que está tudo calmo lê
/// melhor do que a malha nua.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NoticeNote(
      seed: 'empty-board',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mural limpo', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Nenhum aviso por enquanto. Quando a coordenação publicar algo, '
            'aparece aqui.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
