import 'package:flutter/material.dart';
import '../../../core/models/trip_type.dart';

/// Bottom sheet para escolher a direção (ida/volta). Retorna o valor da API.
Future<String?> showTripTypePicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Escolha a direção',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          for (final t in tripTypes)
            ListTile(
              leading: Icon(t.icon),
              title: Text(t.label),
              trailing: current == t.value
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, t.value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
