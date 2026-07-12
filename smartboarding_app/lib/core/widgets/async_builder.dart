import 'package:flutter/material.dart';
import '../utils/async_value.dart';

/// Widget genérico que elimina o boilerplate de loading/error/data
/// em todas as telas. Use com qualquer [AsyncValue<T>].
class AsyncBuilder<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final VoidCallback? onRetry;

  const AsyncBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncLoading() =>
        loading ?? const Center(child: CircularProgressIndicator()),
      AsyncError(:final message) =>
        _ErrorState(message: message, onRetry: onRetry),
      AsyncData(:final value) => builder(value),
    };
  }
}

// ─── Estado de erro padrão ───────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
