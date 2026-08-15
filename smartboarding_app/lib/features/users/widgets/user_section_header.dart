import 'package:flutter/material.dart';
import 'role_meta.dart';

/// Cabeçalho de seção (um por papel), na ordem da hierarquia.
class UserSectionHeader extends StatelessWidget {
  final String role;
  final int count;
  const UserSectionHeader({super.key, required this.role, required this.count});

  @override
  Widget build(BuildContext context) {
    final meta = metaFor(role);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, color: cs.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            meta.plural,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }
}
