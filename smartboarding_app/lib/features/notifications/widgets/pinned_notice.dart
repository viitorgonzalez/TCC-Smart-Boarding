import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../models/notification_model.dart';
import '../widgets/notice_board.dart';

/// Os bilhetes do mural: o aviso e o cartão de mural vazio.
class PinnedNotice extends StatelessWidget {
  final NotificationModel item;
  final bool canManage;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const PinnedNotice({
    super.key,
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
class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key});

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
