import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/notice_board.dart';
import '../widgets/pinned_notice.dart';

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
                  ? const [EmptyNote()]
                  : [
                      for (final item in items)
                        PinnedNotice(
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
