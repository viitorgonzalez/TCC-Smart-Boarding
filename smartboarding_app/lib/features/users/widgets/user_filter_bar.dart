import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'role_meta.dart';

class UserFilterBar extends StatelessWidget {
  final List<UserModel> users;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const UserFilterBar({
    super.key,
    required this.users,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    int countOf(String role) => users.where((u) => u.role == role).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilterChip(
            label: Text('Todos (${users.length})'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final role in roleHierarchy) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(metaFor(role).icon, size: 18),
              label: Text('${metaFor(role).plural} (${countOf(role)})'),
              selected: selected == role,
              onSelected: (_) => onSelected(role),
            ),
          ],
        ],
      ),
    );
  }
}
