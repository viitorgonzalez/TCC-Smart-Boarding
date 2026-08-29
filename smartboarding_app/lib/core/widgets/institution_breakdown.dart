import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Uma rota atende várias instituições (RN15); é esta divisão que o admin usa
/// pra dimensionar o transporte.
class InstitutionBreakdown extends StatelessWidget {
  final Map<String, int> counts;
  final bool compact;

  const InstitutionBreakdown({
    super.key,
    required this.counts,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final names = counts.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      child: Row(
        children: [
          for (var i = 0; i < names.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: compact ? 28 : 34,
                color: AppColors.stroke,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    names[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${counts[names[i]]}',
                    style: TextStyle(
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
